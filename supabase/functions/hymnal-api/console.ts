// SDA Hymnal admin actions for the Qortn Console Manager (signed in with the Qortn Clerk, Qortn admins only).
import { config, db, json } from "./shared.ts";

type Admin = { id: string; email: string | null };
const day = 864e5;
const iso = (ms: number) => new Date(ms).toISOString();

async function audit(admin: Admin, action: string, targetId: string | null, detail: Record<string, unknown> = {}) {
  let targetEmail: string | null = null;
  if (targetId) {
    const { data } = await db.from("hymnal_members").select("email").eq("id", targetId).maybeSingle();
    targetEmail = data?.email ?? null;
  }
  await db.from("hymnal_admin_actions").insert({ admin_id: admin.id, admin_email: admin.email, action, target_id: targetId, target_email: targetEmail, detail });
}

const CONFIG_FIELDS = ["maintenance_message", "announcement", "announcement_until", "min_version_ios", "featured_hymn",
  "ads_enabled", "ads_banner", "ads_interstitial", "ads_every", "ad_banner_unit", "ad_interstitial_unit"];

export async function consoleAction(action: string, body: any, admin: Admin): Promise<Response> {
  switch (action) {
    case "console.overview": {
      const now = Date.now();
      const [members, events, api, deleted] = await Promise.all([
        db.from("hymnal_members").select("id,created_at,last_seen_at,status,saved_count,lists_count,platform,app_version,plus,is_admin").limit(100000),
        db.from("hymnal_events").select("kind,hymn,at,member_id").gte("at", iso(now - 30 * day)).limit(200000),
        db.from("hymnal_api_requests").select("status,ms").gte("at", iso(now - day)).limit(100000),
        db.from("hymnal_deleted_members").select("id", { count: "exact", head: true }),
      ]);
      const ms = members.data ?? [];
      const ev = events.data ?? [];
      const signups: Record<string, number> = {};
      const opens: Record<string, number> = {};
      for (let i = 13; i >= 0; i--) { const k = iso(now - i * day).slice(0, 10); signups[k] = 0; opens[k] = 0; }
      for (const m of ms) { const k = String(m.created_at).slice(0, 10); if (k in signups) signups[k]++; }
      for (const e of ev) { if (e.kind === "open") { const k = String(e.at).slice(0, 10); if (k in opens) opens[k]++; } }
      const versions: Record<string, number> = {};
      for (const m of ms) if (m.app_version) versions[m.app_version] = (versions[m.app_version] ?? 0) + 1;
      const apiRows = api.data ?? [];
      return json({
        users: ms.length,
        newThisWeek: ms.filter((m: any) => Date.parse(m.created_at) > now - 7 * day).length,
        activeToday: ms.filter((m: any) => m.last_seen_at && Date.parse(m.last_seen_at) > now - day).length,
        activeThisWeek: ms.filter((m: any) => m.last_seen_at && Date.parse(m.last_seen_at) > now - 7 * day).length,
        blocked: ms.filter((m: any) => m.status !== "active").length,
        plusMembers: ms.filter((m: any) => m.plus).length,
        admins: ms.filter((m: any) => m.is_admin).length,
        deleted: deleted.count ?? 0,
        savedHymns: ms.reduce((s: number, m: any) => s + (m.saved_count ?? 0), 0),
        lists: ms.reduce((s: number, m: any) => s + (m.lists_count ?? 0), 0),
        opensThisMonth: ev.filter((e: any) => e.kind === "open").length,
        sharesThisMonth: ev.filter((e: any) => e.kind === "share" || e.kind === "card").length,
        apiToday: apiRows.length,
        apiErrorRate: apiRows.length ? apiRows.filter((r: any) => r.status >= 500).length / apiRows.length : 0,
        apiAvgMs: apiRows.length ? Math.round(apiRows.reduce((s: number, r: any) => s + (r.ms ?? 0), 0) / apiRows.length) : 0,
        signups: Object.entries(signups).map(([d, n]) => ({ day: d, count: n })),
        opens: Object.entries(opens).map(([d, n]) => ({ day: d, count: n })),
        versions: Object.entries(versions).map(([v, n]) => ({ version: v, count: n })).sort((a, b) => b.count - a.count),
      });
    }

    case "console.popular": {
      const { data } = await db.from("hymnal_events").select("kind,hymn").gte("at", iso(Date.now() - 30 * day)).not("hymn", "is", null).limit(200000);
      const by: Record<number, { hymn: number; opens: number; shares: number; saves: number }> = {};
      for (const e of data ?? []) {
        const r = (by[e.hymn] ??= { hymn: e.hymn, opens: 0, shares: 0, saves: 0 });
        if (e.kind === "open") r.opens++; else if (e.kind === "save") r.saves++; else r.shares++;
      }
      const rows = Object.values(by).sort((a, b) => (b.opens + b.shares * 3 + b.saves * 2) - (a.opens + a.shares * 3 + a.saves * 2)).slice(0, 50);
      return json({ hymns: rows });
    }

    case "console.users": {
      let q = db.from("hymnal_members").select("id,name,email,provider,is_admin,status,status_reason,suspended_until,created_at,last_seen_at,saved_count,lists_count,platform,app_version,app_build,device,os_version,country,plus,plus_renews")
        .order("created_at", { ascending: false }).limit(500);
      if (body.q) { const t = String(body.q).replace(/[%,()]/g, " ").slice(0, 60); q = q.or(`name.ilike.%${t}%,email.ilike.%${t}%`); }
      const { data } = await q;
      return json({ users: data ?? [] });
    }

    case "console.user": {
      const id = String(body.id ?? "");
      const [{ data: m }, { data: lib }, { data: ev }] = await Promise.all([
        db.from("hymnal_members").select("*").eq("id", id).maybeSingle(),
        db.from("hymnal_library").select("data,updated_at").eq("member_id", id).maybeSingle(),
        db.from("hymnal_events").select("kind,hymn,at").eq("member_id", id).order("at", { ascending: false }).limit(50),
      ]);
      if (!m) return json({ error: "No such member" }, 404);
      return json({ user: m, library: lib?.data ?? null, libraryUpdatedAt: lib?.updated_at ?? null, events: ev ?? [] });
    }

    case "console.user.update": {
      const id = String(body.id ?? "");
      if (!/^user_[A-Za-z0-9]{10,40}$/.test(id)) return json({ error: "No such member" }, 404);
      const upd: Record<string, unknown> = {};
      if (["active", "suspended", "banned"].includes(body.status)) {
        upd.status = body.status;
        upd.status_reason = body.status === "active" ? null : (String(body.reason ?? "").slice(0, 300) || null);
        upd.suspended_until = body.status === "suspended" && body.until ? new Date(body.until).toISOString() : null;
      }
      if (typeof body.isAdmin === "boolean") upd.is_admin = body.isAdmin;
      if (!Object.keys(upd).length) return json({ error: "Nothing to change" }, 400);
      await db.from("hymnal_members").update(upd).eq("id", id);
      await audit(admin, "user.update", id, upd);
      return json({ ok: true });
    }

    case "console.notice": {
      const id = String(body.id ?? "");
      if (!/^user_[A-Za-z0-9]{10,40}$/.test(id)) return json({ error: "No such member" }, 404);
      const title = String(body.title ?? "").trim().slice(0, 120);
      const text = String(body.body ?? "").trim().slice(0, 2000);
      if (!title || !text) return json({ error: "Add a title and a message" }, 400);
      await db.from("hymnal_notices").insert({ member_id: id, kind: body.kind === "warning" ? "warning" : "info", title, body: text });
      await audit(admin, "notice", id, { title });
      return json({ ok: true });
    }

    case "console.config.get":
      return json({ config: await config() });

    case "console.config.set": {
      const upd: Record<string, unknown> = { updated_at: new Date().toISOString() };
      const c = body.config ?? {};
      const text = (v: unknown, max: number) => (v === null || v === "" ? null : String(v).slice(0, max));
      for (const f of CONFIG_FIELDS) {
        if (!(f in c)) continue;
        const v = c[f];
        switch (f) {
          case "ads_enabled": case "ads_banner": case "ads_interstitial": upd[f] = v === true; break;
          case "ads_every": upd[f] = Math.min(20, Math.max(2, Math.trunc(Number(v) || 6))); break;
          case "featured_hymn": { const n = Math.trunc(Number(v)); upd[f] = v === null || v === "" ? null : (n >= 1 && n <= 695 ? n : null); break; }
          case "min_version_ios": upd[f] = v === null || v === "" ? null : (/^\d+(\.\d+){0,2}$/.test(String(v)) ? String(v) : null); break;
          case "ad_banner_unit": case "ad_interstitial_unit":
            upd[f] = v === null || v === "" ? null : (/^ca-app-pub-\d{16}\/\d{10}$/.test(String(v)) ? String(v) : null); break;
          case "announcement_until": upd[f] = v === null || v === "" || Number.isNaN(Date.parse(String(v))) ? null : new Date(String(v)).toISOString(); break;
          default: upd[f] = text(v, 2000);
        }
      }
      await db.from("hymnal_config").update(upd).eq("id", 1);
      await audit(admin, "config.set", null, upd);
      return json({ ok: true, config: await config() });
    }

    case "console.health": {
      const now = Date.now();
      const { data } = await db.from("hymnal_api_requests").select("action,status,ms,at,platform").gte("at", iso(now - day)).order("at", { ascending: false }).limit(20000);
      const rows = data ?? [];
      const byAction: Record<string, { action: string; calls: number; errors: number; ms: number }> = {};
      for (const r of rows) {
        const a = (byAction[r.action] ??= { action: r.action, calls: 0, errors: 0, ms: 0 });
        a.calls++; if (r.status >= 500) a.errors++; a.ms += r.ms ?? 0;
      }
      const actions = Object.values(byAction).map((a) => ({ ...a, avgMs: Math.round(a.ms / a.calls) })).sort((a, b) => b.calls - a.calls);
      const errors = rows.filter((r: any) => r.status >= 500);
      return json({ calls: rows.length, errors: errors.length, actions, recentErrors: errors.slice(0, 30) });
    }

    case "console.words.list": {
      const { data } = await db.from("hymnal_words").select("hymn,credit,updated_at,updated_by").order("hymn").limit(800);
      return json({ words: data ?? [] });
    }

    case "console.words.get": {
      const { data } = await db.from("hymnal_words").select("*").eq("hymn", Math.trunc(Number(body.hymn))).maybeSingle();
      return json({ word: data ?? null });
    }

    case "console.words.set":
    case "console.words.import": {
      const items: any[] = action === "console.words.set" ? [body] : (Array.isArray(body.items) ? body.items : []);
      if (!items.length || items.length > 700) return json({ error: "Send between 1 and 700 hymns" }, 400);
      const rows = [];
      for (const it of items) {
        const hymn = Math.trunc(Number(it.hymn));
        const lyrics = String(it.lyrics ?? "").replace(/\r\n/g, "\n").replace(/\u0000/g, "").trim();
        const credit = String(it.credit ?? "").trim().slice(0, 300) || null;
        if (!(hymn >= 1 && hymn <= 695)) return json({ error: `Hymn number ${it.hymn} isn't between 1 and 695` }, 400);
        if (!lyrics || lyrics.length > 12000) return json({ error: `Hymn ${hymn} needs words (up to 12,000 characters)` }, 400);
        rows.push({ hymn, lyrics, credit, updated_at: new Date().toISOString(), updated_by: admin.email });
      }
      const { error } = await db.from("hymnal_words").upsert(rows);
      if (error) return json({ error: "Couldn't save the words" }, 500);
      await audit(admin, action === "console.words.set" ? "words.set" : "words.import", null, { hymns: rows.map((r) => r.hymn).slice(0, 700) });
      return json({ ok: true, saved: rows.length });
    }

    case "console.words.delete": {
      const hymn = Math.trunc(Number(body.hymn));
      if (!(hymn >= 1 && hymn <= 695)) return json({ error: "No such hymn" }, 400);
      await db.from("hymnal_words").delete().eq("hymn", hymn);
      await audit(admin, "words.delete", null, { hymn });
      return json({ ok: true });
    }

    case "console.activity": {
      const { data } = await db.from("hymnal_admin_actions").select("*").order("at", { ascending: false }).limit(100);
      return json({ actions: data ?? [] });
    }

    default:
      return json({ error: "Unknown console action" }, 400);
  }
}
