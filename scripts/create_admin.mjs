// Creates the Chill Jamaica admin: a Firebase Auth email/password user plus an
// /admins/{uid} Firestore doc (what the app's admin dashboard checks). Uses the
// project's client API key for signUp and the firebase-tools owner OAuth token
// for the Firestore write. Idempotent-ish: if the user already exists it signs
// in to fetch the uid, then upserts the /admins doc.
//
// Requires: Authentication + Email/Password enabled in the Firebase console.
// Usage: node scripts/create_admin.mjs <email> <password> ["Display Name"]
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';

const [, , EMAIL, PASSWORD, DISPLAY_NAME = 'Chill Jamaica Admin'] = process.argv;
if (!EMAIL || !PASSWORD) {
  console.error('Usage: node scripts/create_admin.mjs <email> <password> ["Display Name"]');
  process.exit(1);
}

const PROJECT = 'chill-coconetwater';
const API_KEY = 'AIzaSyDByHPePL0Cw-afjEkESBYtEGM8jOLTfwQ'; // android client key (public)
const ownerToken = JSON.parse(
  readFileSync(`${homedir()}/.config/configstore/firebase-tools.json`, 'utf8'),
).tokens.access_token;

const idp = (method) =>
  `https://identitytoolkit.googleapis.com/v1/accounts:${method}?key=${API_KEY}`;

async function getUid() {
  // Try to create the user; if it exists, sign in instead.
  let res = await fetch(idp('signUp'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASSWORD, returnSecureToken: true }),
  });
  let body = await res.json();
  if (res.ok) {
    console.log(`created auth user: ${EMAIL}`);
    return body.localId;
  }
  const code = body.error?.message ?? '';
  if (code.startsWith('EMAIL_EXISTS')) {
    res = await fetch(idp('signInWithPassword'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: EMAIL, password: PASSWORD, returnSecureToken: true }),
    });
    body = await res.json();
    if (!res.ok) throw new Error(`user exists but sign-in failed: ${body.error?.message}`);
    console.log(`auth user already existed: ${EMAIL}`);
    return body.localId;
  }
  if (code === 'CONFIGURATION_NOT_FOUND' || code === 'OPERATION_NOT_ALLOWED') {
    throw new Error(
      'Firebase Auth Email/Password is not enabled. In the console: ' +
        'Build > Authentication > Get started > Sign-in method > Email/Password > Enable.',
    );
  }
  throw new Error(`signUp failed: ${code}`);
}

async function upsertAdminDoc(uid) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/admins/${uid}`;
  const fields = {
    email: { stringValue: EMAIL },
    displayName: { stringValue: DISPLAY_NAME },
    fcmToken: { stringValue: '' },
    role: { stringValue: 'super_admin' },
    isActive: { booleanValue: true },
    createdAt: { timestampValue: new Date().toISOString() },
  };
  const res = await fetch(url, {
    method: 'PATCH',
    headers: { Authorization: `Bearer ${ownerToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) throw new Error(`admins doc write failed ${res.status}: ${await res.text()}`);
  console.log(`wrote /admins/${uid}`);
}

const uid = await getUid();
await upsertAdminDoc(uid);
console.log('\nAdmin ready. Log in at /admin/login with:');
console.log(`  email:    ${EMAIL}`);
console.log(`  password: ${PASSWORD}`);
