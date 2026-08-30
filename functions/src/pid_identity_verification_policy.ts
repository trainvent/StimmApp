import { DocumentData, Timestamp } from 'firebase-admin/firestore';

export const PID_IDENTITY_VERIFICATION_POLICY_VERSION = 'pid-profile-v1';

export const PID_IDENTITY_VERIFIED_FIELDS = [
  'givenName',
  'surname',
  'dateOfBirth',
  'address',
  'town',
  'state',
  'countryCode',
] as const;

export type PidVerificationMode = 'registration' | 'reverification';

export function pidIdentityVerificationValidUntil(now: Date) {
  const validUntil = new Date(now.getTime());
  const expectedMonth = validUntil.getUTCMonth();
  validUntil.setUTCFullYear(validUntil.getUTCFullYear() + 1);
  if (validUntil.getUTCMonth() !== expectedMonth) {
    // Clamp leap day to the final day of February instead of rolling into March.
    validUntil.setUTCDate(0);
  }
  return validUntil;
}

export function pidIdentityRevision(profile: DocumentData | undefined) {
  const revision = profile?.identityRevision;
  return typeof revision === 'number' && Number.isInteger(revision) && revision >= 0 ?
    revision : 0;
}

export function hasPidVerificationHistory(profile: DocumentData | undefined) {
  return profile?.isVerified === true || profile?.gotVerifiedAt instanceof Timestamp;
}

export function pidVerificationModeForProfile(
  profile: DocumentData | undefined,
): PidVerificationMode {
  return hasPidVerificationHistory(profile) ? 'reverification' : 'registration';
}

export function hasCurrentPidIdentityVerification(
  profile: DocumentData | undefined,
  now: Date,
) {
  const validUntil = profile?.identityVerificationValidUntil;
  const verifiedRevision = profile?.verifiedIdentityRevision;
  return profile?.isVerified === true &&
    profile?.identityVerificationPolicyVersion ===
      PID_IDENTITY_VERIFICATION_POLICY_VERSION &&
    validUntil instanceof Timestamp &&
    validUntil.toMillis() > now.getTime() &&
    typeof verifiedRevision === 'number' &&
    verifiedRevision === pidIdentityRevision(profile);
}
