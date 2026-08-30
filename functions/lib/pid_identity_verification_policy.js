"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PID_IDENTITY_VERIFIED_FIELDS = exports.PID_IDENTITY_VERIFICATION_POLICY_VERSION = void 0;
exports.pidIdentityVerificationValidUntil = pidIdentityVerificationValidUntil;
exports.pidIdentityRevision = pidIdentityRevision;
exports.hasPidVerificationHistory = hasPidVerificationHistory;
exports.pidVerificationModeForProfile = pidVerificationModeForProfile;
exports.hasCurrentPidIdentityVerification = hasCurrentPidIdentityVerification;
const firestore_1 = require("firebase-admin/firestore");
exports.PID_IDENTITY_VERIFICATION_POLICY_VERSION = 'pid-profile-v1';
exports.PID_IDENTITY_VERIFIED_FIELDS = [
    'givenName',
    'surname',
    'dateOfBirth',
    'address',
    'town',
    'state',
    'countryCode',
];
function pidIdentityVerificationValidUntil(now) {
    const validUntil = new Date(now.getTime());
    const expectedMonth = validUntil.getUTCMonth();
    validUntil.setUTCFullYear(validUntil.getUTCFullYear() + 1);
    if (validUntil.getUTCMonth() !== expectedMonth) {
        // Clamp leap day to the final day of February instead of rolling into March.
        validUntil.setUTCDate(0);
    }
    return validUntil;
}
function pidIdentityRevision(profile) {
    const revision = profile === null || profile === void 0 ? void 0 : profile.identityRevision;
    return typeof revision === 'number' && Number.isInteger(revision) && revision >= 0 ?
        revision : 0;
}
function hasPidVerificationHistory(profile) {
    return (profile === null || profile === void 0 ? void 0 : profile.isVerified) === true || (profile === null || profile === void 0 ? void 0 : profile.gotVerifiedAt) instanceof firestore_1.Timestamp;
}
function pidVerificationModeForProfile(profile) {
    return hasPidVerificationHistory(profile) ? 'reverification' : 'registration';
}
function hasCurrentPidIdentityVerification(profile, now) {
    const validUntil = profile === null || profile === void 0 ? void 0 : profile.identityVerificationValidUntil;
    const verifiedRevision = profile === null || profile === void 0 ? void 0 : profile.verifiedIdentityRevision;
    return (profile === null || profile === void 0 ? void 0 : profile.isVerified) === true &&
        (profile === null || profile === void 0 ? void 0 : profile.identityVerificationPolicyVersion) ===
            exports.PID_IDENTITY_VERIFICATION_POLICY_VERSION &&
        validUntil instanceof firestore_1.Timestamp &&
        validUntil.toMillis() > now.getTime() &&
        typeof verifiedRevision === 'number' &&
        verifiedRevision === pidIdentityRevision(profile);
}
//# sourceMappingURL=pid_identity_verification_policy.js.map