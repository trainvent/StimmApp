"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createPidVerificationSession = createPidVerificationSession;
exports.getOwnedPidVerificationSession = getOwnedPidVerificationSession;
exports.transitionPidVerificationSession = transitionPidVerificationSession;
const firestore_1 = require("firebase-admin/firestore");
const node_crypto_1 = require("node:crypto");
const PID_VERIFICATION_SESSIONS_COLLECTION = 'pidVerificationSessions';
const allowedTransitions = {
    pending: ['verified', 'failed', 'expired'],
    verified: ['accepted', 'failed', 'expired'],
    accepted: [],
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
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        expiresAt: value.expiresAt,
    };
}
async function createPidVerificationSession({ sessionId, ownerUid, mode, purpose, expiresAt, }) {
    const traceId = (0, node_crypto_1.randomUUID)();
    const now = firestore_1.Timestamp.now();
    await sessionReference(sessionId).create({
        ownerUid,
        traceId,
        mode,
        purpose,
        state: 'pending',
        credentialFormat: 'dc+sd-jwt',
        credentialType: 'urn:eudi:pid:de:1',
        invocationMethod: 'same-device',
        policyVersion: 'pid-profile-v1',
        createdAt: now,
        updatedAt: now,
        expiresAt: firestore_1.Timestamp.fromDate(expiresAt),
    });
    return traceId;
}
async function getOwnedPidVerificationSession(sessionId, ownerUid) {
    const snapshot = await sessionReference(sessionId).get();
    const session = parseSession(sessionId, snapshot.data());
    return (session === null || session === void 0 ? void 0 : session.ownerUid) === ownerUid ? session : null;
}
async function transitionPidVerificationSession(sessionId, nextState) {
    const reference = sessionReference(sessionId);
    await (0, firestore_1.getFirestore)().runTransaction(async (transaction) => {
        const snapshot = await transaction.get(reference);
        const session = parseSession(sessionId, snapshot.data());
        if (!session) {
            throw new Error('PID verification session record is unavailable.');
        }
        if (session.state === nextState)
            return;
        if (!allowedTransitions[session.state].includes(nextState)) {
            // A terminal state must never be overwritten by a late status poll.
            return;
        }
        const transitionTimestamp = `${nextState}At`;
        transaction.update(reference, {
            state: nextState,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            [transitionTimestamp]: firestore_1.FieldValue.serverTimestamp(),
        });
    });
}
//# sourceMappingURL=pid_verification_session.js.map