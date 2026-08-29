import {
  DocumentData,
  FieldValue,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';
import { randomUUID } from 'node:crypto';

const PID_VERIFICATION_SESSIONS_COLLECTION = 'pidVerificationSessions';

export type PidVerificationMode = 'registration' | 'reverification';

export type PidVerificationSessionState =
  | 'pending'
  | 'verified'
  | 'accepted'
  | 'failed'
  | 'expired';

export type PidVerificationSession = {
  sessionId: string;
  ownerUid: string;
  traceId: string;
  mode: PidVerificationMode;
  purpose: string;
  state: PidVerificationSessionState;
  credentialFormat: 'dc+sd-jwt';
  credentialType: 'urn:eudi:pid:de:1';
  invocationMethod: 'same-device';
  policyVersion: 'pid-profile-v1';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  expiresAt: Timestamp;
};

const allowedTransitions: Record<
  PidVerificationSessionState,
  readonly PidVerificationSessionState[]
> = {
  pending: ['verified', 'failed', 'expired'],
  verified: ['accepted', 'failed', 'expired'],
  accepted: [],
  failed: [],
  expired: [],
};

function sessionReference(sessionId: string) {
  return getFirestore()
    .collection(PID_VERIFICATION_SESSIONS_COLLECTION)
    .doc(sessionId);
}

function parseSession(
  sessionId: string,
  value: DocumentData | undefined,
): PidVerificationSession | null {
  if (!value ||
      typeof value.ownerUid !== 'string' ||
      typeof value.traceId !== 'string' ||
      (value.mode !== 'registration' && value.mode !== 'reverification') ||
      typeof value.purpose !== 'string' ||
      !Object.prototype.hasOwnProperty.call(allowedTransitions, value.state) ||
      value.credentialFormat !== 'dc+sd-jwt' ||
      value.credentialType !== 'urn:eudi:pid:de:1' ||
      value.invocationMethod !== 'same-device' ||
      value.policyVersion !== 'pid-profile-v1' ||
      !(value.createdAt instanceof Timestamp) ||
      !(value.updatedAt instanceof Timestamp) ||
      !(value.expiresAt instanceof Timestamp)) {
    return null;
  }

  return {
    sessionId,
    ownerUid: value.ownerUid,
    traceId: value.traceId,
    mode: value.mode,
    purpose: value.purpose,
    state: value.state as PidVerificationSessionState,
    credentialFormat: value.credentialFormat,
    credentialType: value.credentialType,
    invocationMethod: value.invocationMethod,
    policyVersion: value.policyVersion,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
    expiresAt: value.expiresAt,
  };
}

export async function createPidVerificationSession({
  sessionId,
  ownerUid,
  mode,
  purpose,
  expiresAt,
}: {
  sessionId: string;
  ownerUid: string;
  mode: PidVerificationMode;
  purpose: string;
  expiresAt: Date;
}) {
  const traceId = randomUUID();
  const now = Timestamp.now();

  await sessionReference(sessionId).create({
    ownerUid,
    traceId,
    mode,
    purpose,
    state: 'pending' satisfies PidVerificationSessionState,
    credentialFormat: 'dc+sd-jwt',
    credentialType: 'urn:eudi:pid:de:1',
    invocationMethod: 'same-device',
    policyVersion: 'pid-profile-v1',
    createdAt: now,
    updatedAt: now,
    expiresAt: Timestamp.fromDate(expiresAt),
  });

  return traceId;
}

export async function getOwnedPidVerificationSession(
  sessionId: string,
  ownerUid: string,
) {
  const snapshot = await sessionReference(sessionId).get();
  const session = parseSession(sessionId, snapshot.data());
  return session?.ownerUid === ownerUid ? session : null;
}

export async function transitionPidVerificationSession(
  sessionId: string,
  nextState: PidVerificationSessionState,
) {
  const reference = sessionReference(sessionId);

  await getFirestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const session = parseSession(sessionId, snapshot.data());
    if (!session) {
      throw new Error('PID verification session record is unavailable.');
    }
    if (session.state === nextState) return;
    if (!allowedTransitions[session.state].includes(nextState)) {
      // A terminal state must never be overwritten by a late status poll.
      return;
    }

    const transitionTimestamp = `${nextState}At`;
    transaction.update(reference, {
      state: nextState,
      updatedAt: FieldValue.serverTimestamp(),
      [transitionTimestamp]: FieldValue.serverTimestamp(),
    });
  });
}
