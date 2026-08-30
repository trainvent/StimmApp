import assert from 'node:assert/strict';
import test from 'node:test';
import { Timestamp } from 'firebase-admin/firestore';
import {
  selectLatestResumablePidVerificationSession,
} from '../lib/pid_verification_session.js';

function session(id, state, createdAt, expiresAt = '2026-09-01T00:00:00Z') {
  return {
    sessionId: id,
    ownerUid: 'test-user',
    traceId: `trace-${id}`,
    mode: 'reverification',
    purpose: 'Periodic identity re-verification',
    state,
    credentialFormat: 'dc+sd-jwt',
    credentialType: 'urn:eudi:pid:de:1',
    invocationMethod: 'same-device',
    policyVersion: 'pid-profile-v1',
    createdAt: Timestamp.fromDate(new Date(createdAt)),
    updatedAt: Timestamp.fromDate(new Date(createdAt)),
    expiresAt: Timestamp.fromDate(new Date(expiresAt)),
    ...(state === 'verified' ? {
      verifiedAt: Timestamp.fromDate(new Date(createdAt)),
    } : {}),
  };
}

test('resumes a verified review before newer pending requests', () => {
  const selected = selectLatestResumablePidVerificationSession([
    session('verified', 'verified', '2026-08-30T13:31:00Z'),
    session('newer-pending', 'pending', '2026-08-30T13:35:00Z'),
  ], new Date('2026-08-30T14:00:00Z'));

  assert.equal(selected?.sessionId, 'verified');
});

test('does not resume accepted, failed, or expired sessions', () => {
  const selected = selectLatestResumablePidVerificationSession([
    session('accepted', 'accepted', '2026-08-30T13:35:00Z'),
    session('failed', 'failed', '2026-08-30T13:34:00Z'),
    session(
      'expired',
      'verified',
      '2026-08-30T13:29:59Z',
      '2026-08-30T13:59:59Z',
    ),
  ], new Date('2026-08-30T14:00:00Z'));

  assert.equal(selected, null);
});
