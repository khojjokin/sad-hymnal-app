import { createClient } from "npm:@supabase/supabase-js@2";

export const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

export async function config() {
  const { data } = await db.from("hymnal_config").select("*").eq("id", 1).maybeSingle();
  return data ?? {};
}
