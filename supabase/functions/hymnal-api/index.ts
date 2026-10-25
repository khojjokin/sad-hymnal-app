import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createRemoteJWKSet, decodeJwt, jwtVerify } from "npm:jose@5";
import { consoleAction } from "./console.ts";
import { config, db, json } from "./shared.ts";

// SDA Hymnal API. Checks the Clerk session token itself (Supabase JWT checking is off), then reads and
// writes the hymnal_* tables with the service role.
// - Hymnal users sign in with SDA Hymnal's Clerk (production clerk.hymnal.qortyn.com, dev for test builds).
// - The Qortn Console Manager signs in with the Qortn Clerk (clerk.qortyn.com); its admins manage the
//   hymnal through "console.*" actions.
// - "config", "track", "trending" and "words" also work without signing in, because accounts are optional in the hymnal.

const APP_ISSUERS: Record<string, ReturnType<typeof createRemoteJWKSet>> = {
  "https://clerk.hymnal.qortyn.com": createRemoteJWKSet(new URL("https://clerk.hymnal.qortyn.com/.well-known/jwks.json")),
  "https://becoming-albacore-6794.clerk.accounts.dev": createRemoteJWKSet(new URL("https://becoming-albacore-6794.clerk.accounts.dev/.well-known/jwks.json")),
};
const CONSOLE_ISSUERS: Record<string, ReturnType<typeof createRemoteJWKSet>> = {
  "https://clerk.qortyn.com": createRemoteJWKSet(new URL("https://clerk.qortyn.com/.well-known/jwks.json")),
};

type Caller = { id: string; email: string | null; name: string | null; console: boolean };

async function caller(req: Request): Promise<Caller | null> {
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token || token.startsWith("sb_")) return null;
  try {
    const iss = String(decodeJwt(token).iss ?? "");
    const jwks = APP_ISSUERS[iss] ?? CONSOLE_ISSUERS[iss];
    if (!jwks) return null;
    const { payload } = await jwtVerify(token, jwks, { issuer: iss, clockTolerance: 10 });
    return {
      id: String(payload.sub),
      email: typeof payload.email === "string" ? payload.email : null,
      name: typeof payload.name === "string" && payload.name.trim() ? payload.name.trim() : null,
      console: !!CONSOLE_ISSUERS[iss],
    };
  } catch {
    return null;
  }
}

function platformOf(req: Request) {
  const ua = (req.headers.get("User-Agent") ?? "").toLowerCase();
  if (ua.includes("qortnconsole")) return "console";
  if (ua.includes("android") || ua.includes("okhttp")) return "android";
  if (ua.includes("cfnetwork") || ua.includes("darwin") || ua.includes("iphone")) return "ios";
  return "other";
}

// A simple per-address limit (per server instance) so nobody can flood the API: 120 calls a minute,
// and 30 a minute for the open "track" counter.
const hits = new Map<string, { n: number; t: number; track: number }>();
function limited(req: Request, action: string): boolean {
  const ip = (req.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() || "unknown";
  const now = Date.now();
  let h = hits.get(ip);
  if (!h || now - h.t > 60_000) { h = { n: 0, t: now, track: 0 }; hits.set(ip, h); }
  h.n++;
  if (action === "track") h.track++;
  if (hits.size > 5000) for (const [k, v] of hits) if (now - v.t > 60_000) hits.delete(k);
  return h.n > 120 || h.track > 30;
}

const clean = (s: unknown, max: number) => String(s ?? "").replace(/\u0000/g, "").trim().slice(0, max);
const hymnNo = (n: unknown) => { const v = Math.trunc(Number(n)); return v >= 1 && v <= 695 ? v : null; };

function publicConfig(cfg: any) {
  const live = cfg.announcement && (!cfg.announcement_until || Date.parse(cfg.announcement_until) > Date.now());
  return {
    maintenance: cfg.maintenance_message || null,
    announcement: live ? cfg.announcement : null,
    minVersion: cfg.min_version_ios || null,
    featuredHymn: cfg.featured_hymn ?? null,
    ads: {
      enabled: !!cfg.ads_enabled,
      banner: cfg.ads_banner !== false,
      interstitial: cfg.ads_interstitial !== false,
      every: cfg.ads_every ?? 6,
      bannerId: cfg.ad_banner_unit || "",
      interstitialId: cfg.ad_interstitial_unit || "",
    },
  };
}

/** Why an account can't sync right now (null when it can). Ends expired suspensions. */
async function blocked(id: string): Promise<{ status: string; message: string } | null> {
  const { data } = await db.from("hymnal_members").select("status,status_reason,suspended_until,is_admin").eq("id", id).maybeSingle();
  if (!data || data.is_admin || data.status === "active") return null;
  if (data.status === "suspended" && data.suspended_until && Date.parse(data.suspended_until) <= Date.now()) {
    await db.from("hymnal_members").update({ status: "active", suspended_until: null, status_reason: null }).eq("id", id);
    return null;
  }
  const reason = data.status_reason ? ` Reason: ${data.status_reason}` : "";
  return data.status === "suspended"
    ? { status: "suspended", message: `Your account is paused${data.suspended_until ? " until " + new Date(data.suspended_until).toUTCString().slice(0, 16) : ""}.${reason}` }
    : { status: "banned", message: `Your account has been closed.${reason}` };
}

/** Keeps only a well-formed library: favourites, lists and recent hymns. */
function cleanLibrary(raw: any) {
  const favs = (Array.isArray(raw?.favourites) ? raw.favourites : [])
    .map((f: any) => ({ n: hymnNo(f?.n), at: clean(f?.at, 40) || new Date().toISOString() }))
    .filter((f: any) => f.n).slice(0, 695);
  const lists = (Array.isArray(raw?.lists) ? raw.lists : []).slice(0, 100).map((l: any) => ({
    id: clean(l?.id, 64) || crypto.randomUUID(),
    name: clean(l?.name, 60) || "My list",
    hymns: (Array.isArray(l?.hymns) ? l.hymns : []).map(hymnNo).filter(Boolean).slice(0, 300),
    createdAt: clean(l?.createdAt, 40) || new Date().toISOString(),
    updatedAt: clean(l?.updatedAt, 40) || new Date().toISOString(),
  }));
  const recent = (Array.isArray(raw?.recent) ? raw.recent : []).map(hymnNo).filter(Boolean).slice(0, 30);
  return { favourites: favs, lists, recent, updatedAt: clean(raw?.updatedAt, 40) || new Date().toISOString() };
}

async function handle(req: Request, platform: string, note: (action: string, member: string | null) => void): Promise<Response> {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (Number(req.headers.get("content-length") ?? 0) > 500_000) return json({ error: "That's too large to send." }, 413);
  const body = await req.json().catch(() => ({}));
  const action = String(body.action ?? "");
  if (!/^[a-z.]{1,40}$/i.test(action)) return json({ error: "Unknown action" }, 400);
  if (limited(req, action)) return json({ error: "Too many requests. Please wait a moment." }, 429);
  const me = await caller(req);
  note(action, me?.id ?? null);

  // Open to everyone (accounts are optional).
  if (action === "config") return json({ config: publicConfig(await config()) });
  if (action === "track") {
    const kind = String(body.kind ?? "");
    if (!["open", "share", "save", "card"].includes(kind)) return json({ error: "Unknown event" }, 400);
    await db.from("hymnal_events").insert({ member_id: me && !me.console ? me.id : null, kind, hymn: hymnNo(body.hymn), detail: clean(body.detail, 40) || null, platform });
    return json({ ok: true });
  }

  if (action === "trending") {
    // The most sung hymns this week, for Discover. Counts only, nothing about who.
    const since = new Date(Date.now() - 7 * 864e5).toISOString();
    const { data } = await db.from("hymnal_events").select("kind,hymn").gte("at", since).not("hymn", "is", null).limit(50000);
    const score: Record<number, number> = {};
    for (const e of data ?? []) score[e.hymn] = (score[e.hymn] ?? 0) + (e.kind === "open" ? 1 : 3);
    const hymns = Object.entries(score).sort((x, y) => y[1] - x[1]).slice(0, 10).map(([n, s]) => ({ n: Number(n), score: s }));
    return json({ hymns });
  }

  if (action === "words") {
    // Licensed hymn words added from the console. Everyone gets them; the app asks only for changes since last time.
    const since = typeof body.since === "string" && !Number.isNaN(Date.parse(body.since)) ? new Date(body.since).toISOString() : "1970-01-01T00:00:00Z";
    const { data } = await db.from("hymnal_words").select("hymn,lyrics,credit,updated_at").gt("updated_at", since).order("updated_at").limit(800);
    const { data: gone } = await db.from("hymnal_admin_actions").select("detail,at").eq("action", "words.delete").gt("at", since).limit(800);
    return json({ words: data ?? [], removed: (gone ?? []).map((g: any) => g.detail?.hymn).filter((n: any) => Number.isInteger(n)), now: new Date().toISOString() });
  }

  if (!me) return json({ error: "Not signed in" }, 401);

  if (action.startsWith("console.")) {
    if (!me.console) return json({ error: "Not allowed" }, 403);
    const { data: admin } = await db.from("members").select("is_admin,email").eq("id", me.id).maybeSingle();
    if (!admin?.is_admin) return json({ error: "Admins only" }, 403);
    return consoleAction(action, body, { id: me.id, email: admin.email ?? me.email });
  }
  if (me.console) return json({ error: "Use the SDA Hymnal app to sign in" }, 403);

  const open = ["me", "ackNotice", "deleteAccount"];
  if (!open.includes(action)) {
    const block = await blocked(me.id);
    if (block) return json({ error: block.message, status: block.status }, 403);
  }

  switch (action) {
    case "me": {
      const { data: existing } = await db.from("hymnal_members").select("is_admin,email,name").eq("id", me.id).maybeSingle();
      const row: Record<string, unknown> = {
        id: me.id,
        email: me.email ?? existing?.email ?? null,
        name: me.name ?? existing?.name ?? null,
        provider: clean(body.provider, 20) || null,
        last_seen_at: new Date().toISOString(),
        platform,
      };
      if (typeof body.appVersion === "string") row.app_version = clean(body.appVersion, 20) || null;
      if (typeof body.appBuild === "string") row.app_build = clean(body.appBuild, 20) || null;
      if (typeof body.os === "string") row.os_version = clean(body.os, 30) || null;
      if (typeof body.device === "string") row.device = clean(body.device, 40) || null;
      if (typeof body.country === "string" && /^[A-Z]{2}$/.test(body.country)) row.country = body.country;
      // Plus as the App Store told the app (shown in the console; the app checks the App Store itself).
      if (typeof body.plus === "boolean") row.plus = body.plus;
      if (typeof body.plusRenews === "string" && !Number.isNaN(Date.parse(body.plusRenews))) row.plus_renews = new Date(body.plusRenews).toISOString();
      await db.from("hymnal_members").upsert(row);
      const block = existing?.is_admin ? null : await blocked(me.id);
      const { data: notices } = await db.from("hymnal_notices").select("id,kind,title,body").eq("member_id", me.id).is("read_at", null).order("created_at").limit(10);
      return json({
        isAdmin: existing?.is_admin ?? false,
        status: block?.status ?? "active",
        statusMessage: block?.message ?? null,
        notices: notices ?? [],
        config: publicConfig(await config()),
      });
    }

    case "getLibrary": {
      const { data } = await db.from("hymnal_library").select("data,updated_at").eq("member_id", me.id).maybeSingle();
      return json({ data: data?.data ?? null, updatedAt: data?.updated_at ?? null });
    }

    case "saveLibrary": {
      if (!body.data || typeof body.data !== "object") return json({ error: "Nothing to save" }, 400);
      const lib = cleanLibrary(body.data);
      const now = new Date().toISOString();
      await db.from("hymnal_library").upsert({ member_id: me.id, data: lib, updated_at: now });
      await db.from("hymnal_members").update({ saved_count: lib.favourites.length, lists_count: lib.lists.length, last_seen_at: now }).eq("id", me.id);
      return json({ ok: true, updatedAt: now });
    }

    case "ackNotice":
      await db.from("hymnal_notices").update({ read_at: new Date().toISOString() }).eq("id", body.id).eq("member_id", me.id);
      return json({ ok: true });

    case "deleteAccount": {
      const { data: m } = await db.from("hymnal_members").select("email,name").eq("id", me.id).maybeSingle();
      await db.from("hymnal_deleted_members").upsert({ id: me.id, email: m?.email ?? null, name: m?.name ?? null, reason: "self" });
      await db.from("hymnal_members").delete().eq("id", me.id);
      await db.from("hymnal_events").update({ member_id: null }).eq("member_id", me.id);
      return json({ ok: true });
    }

    default:
      return json({ error: "Unknown action" }, 400);
  }
}

Deno.serve(async (req: Request) => {
  const started = Date.now();
  const platform = platformOf(req);
  let action = "unknown";
  let memberId: string | null = null;
  let res: Response;
  try {
    res = await handle(req, platform, (a, m) => { action = a; memberId = m; });
  } catch (e) {
    console.error(action, e);
    res = json({ error: "Something went wrong. Please try again." }, 500);
  }
  db.from("hymnal_api_requests").insert({ action: action.slice(0, 40), member_id: memberId, status: res.status, ms: Date.now() - started, platform })
    .then(() => {}, () => {});
  const headers = new Headers(res.headers);
  headers.set("Cache-Control", "no-store");
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("Referrer-Policy", "no-referrer");
  return new Response(res.body, { status: res.status, headers });
});
