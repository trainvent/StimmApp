"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createPidVerificationSession = createPidVerificationSession;
exports.getPidVerificationSessionByResultNonce = getPidVerificationSessionByResultNonce;
exports.getOwnedPidVerificationSession = getOwnedPidVerificationSession;
exports.selectLatestResumablePidVerificationSession = selectLatestResumablePidVerificationSession;
exports.pidVerificationSessionResumableUntil = pidVerificationSessionResumableUntil;
exports.getLatestResumablePidVerificationSession = getLatestResumablePidVerificationSession;
exports.transitionPidVerificationSession = transitionPidVerificationSession;
const firestore_1 = require("firebase-admin/firestore");
const node_crypto_1 = require("node:crypto");
const PID_VERIFICATION_SESSIONS_COLLECTION = 'pidVerificationSessions';
const PID_VERIFICATION_REVIEW_WINDOW_MS = 30 * 60 * 1000;
const allowedTransitions = {
    pending: ['verified', 'failed', 'expired', 'cancelled'],
    verified: ['accepted', 'failed', 'expired', 'cancelled'],
    accepted: [],
    cancelled: [],
    failed: [],
    expired: [],
};
function sessionReference(sessionId) {
    return (0, firestore_1.getFirestore)()
        .collection(PID_VERIFICATION_SESSIONS_COLLECTION)
        .doc(sessionId);
}
function parseSession(sessionId, value) {
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
        !(value.createdAt instanceof firestore_1.Timestamp) ||
        !(value.updatedAt instanceof firestore_1.Timestamp) ||
        !(value.expiresAt instanceof firestore_1.Timestamp)) {
        return null;
    }
    return {
        sessionId,
        ownerUid: value.ownerUid,
        traceId: value.traceId,
        mode: value.mode,
        purpose: value.purpose,
        state: value.state,
        credentialFormat: value.credentialFormat,
        credentialType: value.credentialType,
        invocationMethod: value.invocationMethod,
        policyVersion: value.policyVersion,
        resultNonce: value.resultNonce,
        returnTarget: value.returnTarget,
        returnOrigin: value.returnOrigin,
        brand: value.brand === 'vivot' ? 'vivot' : 'stimmapp',
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        expiresAt: value.expiresAt,
        verifiedAt: value.verifiedAt instanceof firestore_1.Timestamp ? value.verifiedAt : undefined,
    };
}
async function createPidVerificationSession({ sessionId, ownerUid, mode, purpose, expiresAt, resultNonce, returnTarget, returnOrigin, brand, }) {
    const traceId = (0, node_crypto_1.randomUUID)();
    const now = firestore_1.Timestamp.now();
    await sessionReference(sessionId).create(Object.assign(Object.assign({ ownerUid,
        traceId,
        mode,
        purpose, state: 'pending', credentialFormat: 'dc+sd-jwt', credentialType: 'urn:eudi:pid:de:1', invocationMethod: 'same-device', policyVersion: 'pid-profile-v1', resultNonce,
        returnTarget }, (returnOrigin ? { returnOrigin } : {})), { brand: brand !== null && brand !== void 0 ? brand : 'stimmapp', createdAt: now, updatedAt: now, expiresAt: firestore_1.Timestamp.fromDate(expiresAt) }));
    return traceId;
}
async function getPidVerificationSessionByResultNonce(resultNonce) {
    const snapshot = await (0, firestore_1.getFirestore)()
        .collection(PID_VERIFICATION_SESSIONS_COLLECTION)
        .where('resultNonce', '==', resultNonce)
        .limit(1)
        .get();
    const document = snapshot.docs[0];
    return document ? parseSession(document.id, document.data()) : null;
}
async function getOwnedPidVerificationSession(sessionId, ownerUid) {
    const snapshot = await sessionReference(sessionId).get();
    const session = parseSession(sessionId, snapshot.data());
    return (session === null || session === void 0 ? void 0 : session.ownerUid) === ownerUid ? session : null;
}
function selectLatestResumablePidVerificationSession(sessions, now) {
    var _a;
    return (_a = sessions
        .filter((session) => (session.state === 'verified' || session.state === 'pending') &&
        pidVerificationSessionResumableUntil(session).getTime() > now.getTime())
        .sort((left, right) => {
        // A completed presentation awaiting explicit consent is more valuable
        // than a newer request that has not received a wallet response yet.
        const leftPriority = left.state === 'verified' ? 1 : 0;
        const rightPriority = right.state === 'verified' ? 1 : 0;
        return rightPriority - leftPriority ||
            right.createdAt.toMillis() - left.createdAt.toMillis();
    })[0]) !== null && _a !== void 0 ? _a : null;
}
function pidVerificationSessionResumableUntil(session) {
    if (session.state === 'verified' && session.verifiedAt) {
        return new Date(session.verifiedAt.toMillis() + PID_VERIFICATION_REVIEW_WINDOW_MS);
    }
    return session.expiresAt.toDate();
}
async function getLatestResumablePidVerificationSession(ownerUid) {
    const snapshot = await (0, firestore_1.getFirestore)()
        .collection(PID_VERIFICATION_SESSIONS_COLLECTION)
        .where('ownerUid', '==', ownerUid)
        .get();
    const sessions = snapshot.docs
        .map((document) => parseSession(document.id, document.data()))
        .filter((session) => session != null);
    return selectLatestResumablePidVerificationSession(sessions, new Date());
}
async function transitionPidVerificationSession(sessionId, nextState) {
    const reference = sessionReference(sessionId);
    return (0, firestore_1.getFirestore)().runTransaction(async (transaction) => {
        const snapshot = await transaction.get(reference);
        const session = parseSession(sessionId, snapshot.data());
        if (!session) {
            throw new Error('PID verification session record is unavailable.');
        }
        if (session.state === nextState)
            return session.state;
        if (!allowedTransitions[session.state].includes(nextState)) {
            // A terminal state must never be overwritten by a late status poll.
            return session.state;
        }
        if (nextState === 'verified' && pidVerificationSessionResumableUntil(session).getTime() <= Date.now()) {
            transaction.update(reference, { state: 'expired', updatedAt: firestore_1.FieldValue.serverTimestamp(), expiredAt: firestore_1.FieldValue.serverTimestamp() });
            return 'expired';
        }
        const transitionTimestamp = `${nextState}At`;
        transaction.update(reference, {
            state: nextState,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            [transitionTimestamp]: firestore_1.FieldValue.serverTimestamp(),
        });
        return nextState;
    });
}
//# sourceMappingURL=pid_verification_session.js.map