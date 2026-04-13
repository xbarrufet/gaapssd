/**
 * notify-visit-ended
 *
 * Triggered by a Supabase Database Webhook on UPDATE to public.visits
 * when ended_at transitions from NULL to a value (visit closed).
 *
 * Configure webhook in Supabase Dashboard:
 *   Table: visits | Event: UPDATE | URL: {project_url}/functions/v1/notify-visit-ended
 *   Headers: Authorization: Bearer {service_role_key}
 *
 * Required Supabase secrets:
 *   FIREBASE_SERVICE_ACCOUNT  — service account JSON (Firebase Console → Project Settings → Service accounts)
 *   FIREBASE_PROJECT_ID       — Firebase project ID
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// FCM HTTP v1 helper (inlined to keep the function self-contained)
// ---------------------------------------------------------------------------

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

interface FcmPayload {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  collapseKey?: string;
}

function base64url(input: string | Uint8Array): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

async function createJwt(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const signingInput = `${header}.${claims}`;
  const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "").replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(signingInput));
  return `${signingInput}.${base64url(new Uint8Array(sig))}`;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const jwt = await createJwt(sa);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  return json.access_token as string;
}

async function sendFcmNotification(payload: FcmPayload): Promise<void> {
  const sa: ServiceAccount = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID")!;
  const token = await getAccessToken(sa);

  const message: Record<string, unknown> = {
    token: payload.token,
    notification: { title: payload.title, body: payload.body },
  };
  if (payload.data) message.data = payload.data;
  if (payload.collapseKey) {
    message.android = { collapse_key: payload.collapseKey };
    message.apns = { headers: { "apns-collapse-id": payload.collapseKey } };
  }

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
      body: JSON.stringify({ message }),
    },
  );
  if (!res.ok) throw new Error(`FCM error (${res.status}): ${await res.text()}`);
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

interface VisitRow {
  id: string;
  garden_id: string;
  gardener_id: string;
  started_at: string;
  ended_at: string | null;
}

interface WebhookPayload {
  type: "UPDATE";
  table: string;
  record: VisitRow;
  old_record: VisitRow;
  schema: string;
}

function formatDuration(startedAt: Date, endedAt: Date): string {
  const totalMinutes = Math.round((endedAt.getTime() - startedAt.getTime()) / 60_000);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours === 0) return `${minutes} min`;
  if (minutes === 0) return `${hours} h`;
  return `${hours} h ${minutes} min`;
}

Deno.serve(async (req: Request) => {
  try {
    const payload: WebhookPayload = await req.json();
    const visit = payload.record;
    const oldVisit = payload.old_record;

    // Only process actual close transitions (ended_at: null → value)
    if (
      payload.type !== "UPDATE" ||
      payload.table !== "visits" ||
      oldVisit.ended_at !== null ||
      visit.ended_at === null
    ) {
      return new Response("Ignored", { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: garden, error: gardenError } = await supabase
      .from("gardens")
      .select("name, client_id, client_profiles!inner(user_id)")
      .eq("id", visit.garden_id)
      .single();

    if (gardenError || !garden) {
      console.error("Garden not found:", gardenError?.message);
      return new Response("Garden not found", { status: 200 });
    }

    const clientUserId = (garden as any).client_profiles.user_id as string;

    const { data: tokenRow } = await supabase
      .from("device_tokens")
      .select("token")
      .eq("user_id", clientUserId)
      .order("updated_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!tokenRow) return new Response("No device token", { status: 200 });

    const duration = formatDuration(
      new Date(visit.started_at),
      new Date(visit.ended_at!),
    );

    await sendFcmNotification({
      token: tokenRow.token,
      title: "✅ Visita finalizada",
      body: `${garden.name} · Duración: ${duration}`,
      data: { type: "visit_ended", visitId: visit.id },
      collapseKey: `visit_${visit.id}`,
    });

    return new Response("OK", { status: 200 });
  } catch (err) {
    console.error("notify-visit-ended error:", err);
    return new Response("Internal error", { status: 500 });
  }
});
