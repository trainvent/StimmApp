import {
  DocumentData,
  FieldValue,
  Timestamp,
  getFirestore,
} from 'firebase-admin/firestore';
import { randomUUID } from 'node:crypto';

const PID_VERIFICATION_SESSIONS_COLLECTION = 'pidVerificationSessions';
const PID_VERIFICATION_REVIEW_WINDOW_MS = 30 * 60 * 1000;

export type PidVerificationMode = 'registration' | 'reverification';
export type PidVerificationReturnTarget = 'native' | 'web';

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
  resultNonce: string;
  returnTarget: PidVerificationReturnTarget;
  returnOrigin?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  expiresAt: Timestamp;
  verifiedAt?: Timestamp;
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
      typeof value.resultNonce !== 'string' ||
      (value.returnTarget !== 'native' && value.returnTarget !== 'web') ||
      (value.returnOrigin !== undefined && typeof value.returnOrigin !== 'string') ||
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
    resultNonce: value.resultNonce,
    returnTarget: value.returnTarget,
    returnOrigin: value.returnOrigin,
    createdAt: value.createdAt,
    updatedAt: value.updatedAt,
    expiresAt: value.expiresAt,
    verifiedAt: value.verifiedAt instanceof Timestamp ? value.verifiedAt : undefined,
  };
}

export async function createPidVerificationSession({
  sessionId,
  ownerUid,
  mode,
  purpose,
  expiresAt,
  resultNonce,
  returnTarget,
  returnOrigin,
}: {
  sessionId: string;
  ownerUid: string;
  mode: PidVerificationMode;
  purpose: string;
  expiresAt: Date;
  resultNonce: string;
  returnTarget: PidVerificationReturnTarget;
  returnOrigin?: string;
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
    resultNonce,
    returnTarget,
    ...(returnOrigin ? { returnOrigin } : {}),
    createdAt: now,
    updatedAt: now,
    expiresAt: Timestamp.fromDate(expiresAt),
  });

  return traceId;
}

export async function getPidVerificationSessionByResultNonce(
  resultNonce: string,
) {
  const snapshot = await getFirestore()
    .collection(PID_VERIFICATION_SESSIONS_COLLECTION)
    .where('resultNonce', '==', resultNonce)
    .limit(1)
    .get();
  const document = snapshot.docs[0];
  return document ? parseSession(document.id, document.data()) : null;
}

export async function getOwnedPidVerificationSession(
  sessionId: string,
  ownerUid: string,
) {
  const snapshot = await sessionReference(sessionId).get();
  const session = parseSession(sessionId, snapshot.data());
  return session?.ownerUid === ownerUid ? session : null;
}

export function selectLatestResumablePidVerificationSession(
  sessions: readonly PidVerificationSession[],
  now: Date,
) {
  return sessions
    .filter((session) =>
      (session.state === 'verified' || session.state === 'pending') &&
      pidVerificationSessionResumableUntil(session).getTime() > now.getTime(),
    )
    .sort((left, right) => {
      // A completed presentation awaiting explicit consent is more valuable
      // than a newer request that has not received a wallet response yet.
      const leftPriority = left.state === 'verified' ? 1 : 0;
      const rightPriority = right.state === 'verified' ? 1 : 0;
      return rightPriority - leftPriority ||
        right.createdAt.toMillis() - left.createdAt.toMillis();
    })[0] ?? null;
}

export function pidVerificationSessionResumableUntil(
  session: PidVerificationSession,
) {
  if (session.state === 'verified' && session.verifiedAt) {
    return new Date(
      session.verifiedAt.toMillis() + PID_VERIFICATION_REVIEW_WINDOW_MS,
    );
  }
  return session.expiresAt.toDate();
}

export async function getLatestResumablePidVerificationSession(
  ownerUid: string,
) {
  const snapshot = await getFirestore()
    .collection(PID_VERIFICATION_SESSIONS_COLLECTION)
    .where('ownerUid', '==', ownerUid)
    .get();
  const sessions = snapshot.docs
    .map((document) => parseSession(document.id, document.data()))
    .filter((session): session is PidVerificationSession => session != null);
  return selectLatestResumablePidVerificationSession(sessions, new Date());
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
