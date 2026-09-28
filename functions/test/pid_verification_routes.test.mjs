import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { once } from 'node:events';
import test from 'node:test';
import express from 'express';
import { registerPidSessionRoutes } from '../lib/pid_verification_routes.js';
import { createPidVerificationSession, transitionPidVerificationSession } from '../lib/pid_verification_session.js';
const require = createRequire(import.meta.url);
const { HttpsError } = require('firebase-functions/v2/https');
const firestoreModule = require('firebase-admin/firestore');
const { Timestamp } = firestoreModule;

// Transactional in-memory Firestore adapter. Execute the production session
// repository and HTTP handlers; replace only external auth, wallet and storage.
function store() {
  const records = new Map();
  let queue = Promise.resolve();
  const snapshot = (path) => ({ id: path.split('/').at(-1), data: () => records.get(path) });
  const ref = (path) => ({
    path,
    get: async () => snapshot(path),
    create: async (data) => { assert.ok(!records.has(path)); records.set(path, data); },
  });
  const timestampValues = (data) => Object.fromEntries(Object.entries(data).map(([key, value]) =>
    [key, value?.constructor?.name === 'ServerTimestampTransform' ? Timestamp.now() : value]));
  return {
    records,
    beforeTransaction: null,
    collection(name) {
      return {
        doc: (id) => ref(`${name}/${id}`),
        where: (key, _operator, value) => ({
          get: async () => ({ docs: [...records].filter(([path, data]) =>
            path.startsWith(`${name}/`) && data[key] === value).map(([path]) => snapshot(path)) }),
        }),
      };
    },
    runTransaction(callback) {
      const run = queue.then(async () => {
        this.beforeTransaction?.();
        this.beforeTransaction = null;
        const writes = [];
        const result = await callback({
          get: async (reference) => snapshot(reference.path),
          set: (reference, data) => writes.push([reference.path, data]),
          update: (reference, data) => writes.push([reference.path, data]),
        });
        for (const [path, data] of writes) records.set(path, { ...records.get(path), ...timestampValues(data) });
        return result;
      });
      queue = run.catch(() => {});
      return run;
    },
  };
}
const claims = {
  givenName: 'Test', familyName: 'Person', birthdate: '1990-01-01',
  streetAddress: 'Teststraße 1', postalCode: '10115', locality: 'Berlin',
  country: 'DE', region: null, formattedAddress: 'Teststraße 1, 10115 Berlin',
};

async function fixture(t) {
  const db = store();
  t.mock.method(firestoreModule, 'getFirestore', () => db);
  let walletReads = 0;
  let beforeClaims;
  const app = express();
  registerPidSessionRoutes(app, {
    requireFirebaseUser: async (req) => {
      if (!req.header('authorization')) throw new HttpsError('unauthenticated', 'Sign in');
      return { uid: req.header('authorization') };
    },
    ensurePidVerifierAgent: async () => ({ agent: { openid4vc: { verifier: {
      getVerificationSessionById: async () => { walletReads++; return { state: 'ResponseVerified' }; },
    } } } }),
    getVerifiedPidClaims: async () => { beforeClaims?.(); return claims; },
    normalizeVerifiedPidClaimsForProfile: (value) => value,
  });
  const server = app.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const call = async (path, user = 'owner', method = 'GET') => {
    const response = await globalThis.fetch(`http://127.0.0.1:${server.address().port}/oid4vp/${path}`, {
      method, headers: user ? { authorization: user } : {},
    });
    return { status: response.status, body: await response.json() };
  };
  const seed = async (id = 'one', ownerUid = 'owner') => {
    await createPidVerificationSession({ sessionId: id, ownerUid, mode: 'registration',
      purpose: 'Registration', expiresAt: new Date(Date.now() + 300000),
      resultNonce: `nonce-${id}`, returnTarget: 'native' });
  };
  return { db, call, seed, walletReads: () => walletReads,
    beforeClaims: (callback) => { beforeClaims = callback; } };
}

test('another user cannot read, accept, cancel or resume a session', async (t) => {
  const f = await fixture(t); await f.seed();
  for (const [path, method] of [['status/one', 'GET'], ['accept/one', 'POST'], ['cancel/one', 'POST']]) {
    assert.equal((await f.call(path, 'intruder', method)).status, 404);
  }
  assert.equal((await f.call('resumable', 'intruder')).body.session, null);
  assert.equal((await f.call('status/one', null)).status, 401);
  assert.equal(f.walletReads(), 0);
  assert.equal(f.db.records.get('pidVerificationSessions/one').state, 'pending');
  assert.equal(f.db.records.has('users/intruder'), false);
});

test('expired pending and verified review sessions cannot be accepted', async (t) => {
  const f = await fixture(t);
  for (const id of ['pending', 'verified']) {
    await f.seed(id);
    const data = f.db.records.get(`pidVerificationSessions/${id}`);
    data.expiresAt = Timestamp.fromMillis(Date.now() - 1);
    if (id === 'verified') {
      data.state = 'verified'; data.verifiedAt = Timestamp.fromMillis(Date.now() - 1800001);
    }
    assert.equal((await f.call(`accept/${id}`, 'owner', 'POST')).status, 409);
    assert.equal((await f.call(`status/${id}`)).body.status, 'expired');
  }
  assert.equal(f.walletReads(), 0);
  assert.equal(f.db.records.has('users/owner'), false);
});

test('expiry during acceptance is checked inside the transaction', async (t) => {
  const f = await fixture(t); await f.seed();
  f.beforeClaims(() => {
    f.db.records.get('pidVerificationSessions/one').verifiedAt = Timestamp.fromMillis(Date.now() - 1800001);
  });
  const response = await f.call('accept/one', 'owner', 'POST');
  assert.equal(response.status, 409); assert.equal(response.body.code, 'expired');
  assert.equal(f.db.records.has('users/owner'), false);
});

test('parallel and repeated acceptance increments the identity revision once', async (t) => {
  const f = await fixture(t); await f.seed();
  const results = await Promise.all(Array.from({ length: 4 }, () => f.call('accept/one', 'owner', 'POST')));
  assert.ok(results.every((result) => result.status === 200));
  assert.equal(results.filter((result) => !result.body.alreadyAccepted).length, 1);
  assert.equal(f.db.records.get('users/owner').identityRevision, 1);
  const verifiedAt = f.db.records.get('users/owner').gotVerifiedAt;
  assert.equal((await f.call('accept/one', 'owner', 'POST')).body.alreadyAccepted, true);
  assert.equal(f.db.records.get('users/owner').gotVerifiedAt, verifiedAt);
  await transitionPidVerificationSession('one', 'expired');
  assert.equal((await f.call('status/one')).body.status, 'accepted');
});

test('concurrent sessions remain independent and profile revisions do not get lost', async (t) => {
  const f = await fixture(t); await f.seed('one'); await f.seed('two'); await f.seed('other', 'other-owner');
  await transitionPidVerificationSession('one', 'verified');
  assert.equal((await f.call('resumable')).body.session.sessionId, 'one');
  const results = await Promise.all(['one', 'two'].map((id) => f.call(`accept/${id}`, 'owner', 'POST')));
  assert.ok(results.every((result) => result.status === 200));
  assert.equal(f.db.records.get('users/owner').identityRevision, 2);
  assert.equal(f.db.records.get('pidVerificationSessions/other').state, 'pending');
  assert.equal((await f.call('resumable')).body.session, null);
});

test('cancellation is terminal and idempotent without overwriting accepted sessions', async (t) => {
  const f = await fixture(t); await f.seed();
  for (let i = 0; i < 2; i++) assert.equal((await f.call('cancel/one', 'owner', 'POST')).body.status, 'cancelled');
  assert.equal((await f.call('accept/one', 'owner', 'POST')).status, 409);
  assert.equal((await f.call('status/one')).body.status, 'cancelled');
  assert.equal((await f.call('resumable')).body.session, null);
  await transitionPidVerificationSession('one', 'verified');
  assert.equal(f.db.records.get('pidVerificationSessions/one').state, 'cancelled');
  await f.seed('two'); await f.call('accept/two', 'owner', 'POST');
  assert.equal((await f.call('cancel/two', 'owner', 'POST')).body.status, 'accepted');
});
