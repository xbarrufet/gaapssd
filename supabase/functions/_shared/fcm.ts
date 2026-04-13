/**
 * FCM HTTP v1 helper (replaces legacy API).
 *
 * The legacy FCM API (Server Key) was deprecated June 2023 and is now disabled.
 * The v1 API requires a short-lived OAuth2 Bearer token obtained from a
 * Firebase service account JSON stored as the FIREBASE_SERVICE_ACCOUNT secret.
 *
 * Required Supabase secrets:
 *   FIREBASE_SERVICE_ACCOUNT  — full service account JSON string
 *   FIREBASE_PROJECT_ID       — Firebase project ID (e.g. "gapp-2025")
 *
 * collapseKey: sets both android.collapseKey and apns-collapse-id so that if
 * a device is offline, the exit notification silently replaces the entry one
 * before delivery (FR-05).
 */

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

export interface FcmPayload {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  collapseKey?: string;
}

// ---------------------------------------------------------------------------
// OAuth2: sign a JWT with the service account private key (Web Crypto / Deno)
// ---------------------------------------------------------------------------

function base64url(input: string | Uint8Array): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

async function createJwt(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const signingInput = `${header}.${claims}`;

  // Strip PEM envelope and decode base64
  const pemContents = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) =>
    c.charCodeAt(0),
  );

  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signingInput),
  );

  const signature = base64url(new Uint8Array(signatureBuffer));
  return `${signingInput}.${signature}`;
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const jwt = await createJwt(serviceAccount);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`OAuth2 token exchange failed (${response.status}): ${text}`);
  }

  const json = await response.json();
  return json.access_token as string;
}

// ---------------------------------------------------------------------------
// Send notification via FCM HTTP v1
// ---------------------------------------------------------------------------

export async function sendFcmNotification(payload: FcmPayload): Promise<void> {
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  const projectId = Deno.env.get("FIREBASE_PROJECT_ID");

  if (!serviceAccountJson || !projectId) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT and FIREBASE_PROJECT_ID env vars are required",
    );
  }

  const serviceAccount: ServiceAccount = JSON.parse(serviceAccountJson);
  const accessToken = await getAccessToken(serviceAccount);

  const message: Record<string, unknown> = {
    token: payload.token,
    notification: {
      title: payload.title,
      body: payload.body,
    },
  };

  if (payload.data) {
    message.data = payload.data;
  }

  if (payload.collapseKey) {
    message.android = { collapse_key: payload.collapseKey };
    message.apns = {
      headers: { "apns-collapse-id": payload.collapseKey },
    };
  }

  const url =
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({ message }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`FCM v1 request failed (${response.status}): ${text}`);
  }
}
