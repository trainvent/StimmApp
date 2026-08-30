import assert from 'node:assert/strict';
import test from 'node:test';
import { Timestamp } from 'firebase-admin/firestore';
import {
  PID_IDENTITY_VERIFICATION_POLICY_VERSION,
  hasCurrentPidIdentityVerification,
  pidIdentityVerificationValidUntil,
  pidVerificationModeForProfile,
} from '../lib/pid_identity_verification_policy.js';

test('uses registration only before the first successful verification', () => {
  assert.equal(pidVerificationModeForProfile(undefined), 'registration');
  assert.equal(
    pidVerificationModeForProfile({ gotVerifiedAt: Timestamp.now() }),
    'reverification',
  );
});

test('creates a twelve-calendar-month validity period', () => {
  assert.equal(
    pidIdentityVerificationValidUntil(
      new Date('2024-02-29T12:30:00.000Z'),
    ).toISOString(),
    '2025-02-28T12:30:00.000Z',
  );
});

test('requires valid time, current policy, and matching identity revision', () => {
  const now = new Date('2026-08-30T12:00:00.000Z');
  const profile = {
    isVerified: true,
    identityVerificationPolicyVersion:
      PID_IDENTITY_VERIFICATION_POLICY_VERSION,
    identityVerificationValidUntil: Timestamp.fromDate(
      new Date('2027-08-30T12:00:00.000Z'),
    ),
    identityRevision: 3,
    verifiedIdentityRevision: 3,
  };

  assert.equal(hasCurrentPidIdentityVerification(profile, now), true);
  assert.equal(
    hasCurrentPidIdentityVerification(
      { ...profile, identityRevision: 4 },
      now,
    ),
    false,
  );
  assert.equal(
    hasCurrentPidIdentityVerification(
      { ...profile, identityVerificationPolicyVersion: 'pid-profile-v0' },
      now,
    ),
    false,
  );
  assert.equal(
    hasCurrentPidIdentityVerification(
      {
        ...profile,
        identityVerificationValidUntil: Timestamp.fromDate(now),
      },
      now,
    ),
    false,
  );
});
