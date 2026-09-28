import express from 'express';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';
import {
  PID_IDENTITY_VERIFICATION_POLICY_VERSION, PID_IDENTITY_VERIFIED_FIELDS,
  pidIdentityRevision, pidIdentityVerificationValidUntil,
} from './pid_identity_verification_policy.js';
import {
  getLatestResumablePidVerificationSession, getOwnedPidVerificationSession,
  pidVerificationSessionResumableUntil, transitionPidVerificationSession,
} from './pid_verification_session.js';
import { logPidVerifierEvent, pidVerifierErrorCategory } from './pid_verifier_logging.js';
import type { VerifiedPidClaims } from './pid_verification.js';

// Keep authentication, persistence and the wallet verifier injectable so the
// actual HTTP handlers can be regression-tested without credentials or a wallet.
export function registerPidSessionRoutes(pidVerifierApp: express.Express, dependencies: {
  requireFirebaseUser: (request: express.Request) => Promise<{ uid: string }>;
  ensurePidVerifierAgent: () => Promise<{ agent: any }>;
  getVerifiedPidClaims: (agent: any, sessionId: string) => Promise<VerifiedPidClaims>;
  normalizeVerifiedPidClaimsForProfile: (claims: VerifiedPidClaims) => VerifiedPidClaims;
}) {
  const {
    requireFirebaseUser, ensurePidVerifierAgent, getVerifiedPidClaims,
    normalizeVerifiedPidClaimsForProfile,
  } = dependencies;
  pidVerifierApp.get('/oid4vp/resumable', async (request, response) => {
    const startedAt = Date.now();
    try {
      const user = await requireFirebaseUser(request);
      const session = await getLatestResumablePidVerificationSession(user.uid);
      response.json({
        session: session ? {
          sessionId: session.sessionId,
          status: session.state,
          mode: session.mode,
          purpose: session.purpose,
          expiresAt: pidVerificationSessionResumableUntil(session).toISOString(),
        } : null,
      });
    } catch (error) {
      const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
      if (status === 500) logPidVerifierEvent({
        event: 'operation_failed', outcome: 'failure', status,
        latencyMs: Date.now() - startedAt, errorCategory: pidVerifierErrorCategory(error),
        errorCode: 'resumable_session_failed', protocolStage: 'status_check',
      });
      response.status(status).json({
        error: status === 401 ? 'Authentication is required.' :
          'The PID verification session could not be restored.',
      });
    }
  });

  pidVerifierApp.get('/oid4vp/status/:sessionId', async (request, response) => {
    const startedAt = Date.now();
    try {
      const user = await requireFirebaseUser(request);
      const sessionId = request.params.sessionId;
      const persistedSession = await getOwnedPidVerificationSession(
        sessionId,
        user.uid,
      );
      if (!persistedSession) {
        response.status(404).json({ error: 'Verification session not found.' });
        return;
      }

      if (persistedSession.state === 'cancelled') {
        response.json({ status: 'cancelled' });
        return;
      }
      if (persistedSession.state === 'failed') {
        logPidVerifierEvent({ traceId: persistedSession.traceId, event: 'session_failed', outcome: 'failure', status: 200, latencyMs: Date.now() - startedAt, errorCategory: 'validation', errorCode: 'previously_failed', validationOutcome: 'failure', protocolStage: 'status_check' });
        response.json({ status: 'failed', error: 'The PID presentation could not be verified.' });
        return;
      }
      if (persistedSession.state === 'accepted') {
        response.json({ status: 'accepted' });
        return;
      }
      if (persistedSession.state === 'expired' ||
          pidVerificationSessionResumableUntil(persistedSession).getTime() <= Date.now()) {
        await transitionPidVerificationSession(sessionId, 'expired');
        logPidVerifierEvent({ traceId: persistedSession.traceId, event: 'session_expired', outcome: 'failure', status: 200, latencyMs: Date.now() - startedAt, errorCategory: 'validation', errorCode: 'session_expired', validationOutcome: 'not_applicable', protocolStage: 'status_check' });
        response.json({ status: 'expired' });
        return;
      }

      const { agent } = await ensurePidVerifierAgent();
      const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
      if (session.state === 'ResponseVerified') {
        const state = await transitionPidVerificationSession(sessionId, 'verified');
        if (state !== 'verified') {
          response.json({ status: state });
          return;
        }
        logPidVerifierEvent({ traceId: persistedSession.traceId, event: 'session_verified', outcome: 'success', status: 200, latencyMs: Date.now() - startedAt, validationOutcome: 'success', protocolStage: 'status_check' });
        const claims = await getVerifiedPidClaims(agent, sessionId);
        response.json({
          status: 'verified',
          claims,
          normalizedClaims: normalizeVerifiedPidClaimsForProfile(claims),
        });
        return;
      }
      if (session.state === 'Error') {
        await transitionPidVerificationSession(sessionId, 'failed');
        logPidVerifierEvent({ traceId: persistedSession.traceId, event: 'session_failed', outcome: 'failure', status: 200, latencyMs: Date.now() - startedAt, errorCategory: 'validation', errorCode: 'presentation_verification_failed', validationOutcome: 'failure', protocolStage: 'status_check' });
        response.json({ status: 'failed', error: 'The PID presentation could not be verified.' });
        return;
      }
      response.json({ status: 'pending' });
    } catch (error) {
      const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
      if (status === 500) logPidVerifierEvent({
        event: 'operation_failed', outcome: 'failure', status,
        latencyMs: Date.now() - startedAt, errorCategory: pidVerifierErrorCategory(error),
        errorCode: 'status_read_failed', protocolStage: 'status_check',
      });
      response.status(status).json({
        error: status === 401 ? 'Authentication is required.' : 'The PID verification status is unavailable.',
      });
    }
  });

  pidVerifierApp.post('/oid4vp/accept/:sessionId', async (request, response) => {
    const startedAt = Date.now();
    try {
      const user = await requireFirebaseUser(request);
      const sessionId = request.params.sessionId;
      const persistedSession = await getOwnedPidVerificationSession(
        sessionId,
        user.uid,
      );
      if (!persistedSession) {
        response.status(404).json({ error: 'Verification session not found.' });
        return;
      }
      if (persistedSession.state === 'accepted') {
        response.json({ ok: true, alreadyAccepted: true });
        return;
      }
      if (['cancelled', 'failed', 'expired'].includes(persistedSession.state)) {
        response.status(409).json({ code: persistedSession.state, error: 'This verification session is closed.' });
        return;
      }
      if (pidVerificationSessionResumableUntil(persistedSession).getTime() <= Date.now()) {
        await transitionPidVerificationSession(sessionId, 'expired');
        response.status(409).json({ code: 'expired', error: 'The PID verification request expired.' });
        return;
      }

      const { agent } = await ensurePidVerifierAgent();
      const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
      if (session.state !== 'ResponseVerified') {
        response.status(409).json({ error: 'The PID presentation has not been verified.' });
        return;
      }
      const state = await transitionPidVerificationSession(sessionId, 'verified');
      if (state === 'accepted') {
        response.json({ ok: true, alreadyAccepted: true });
        return;
      }
      if (state !== 'verified') {
        response.status(409).json({ code: state });
        return;
      }

      const claims = normalizeVerifiedPidClaimsForProfile(
        await getVerifiedPidClaims(agent, sessionId),
      );
      if (!claims.givenName || !claims.familyName ||
          !claims.birthdate || !/^\d{4}-\d{2}-\d{2}$/.test(claims.birthdate) ||
          !claims.streetAddress || !claims.postalCode || !claims.locality ||
          !claims.country || !claims.formattedAddress) {
        response.status(422).json({
          error: 'The verified PID is missing identity or full residential address fields.',
        });
        return;
      }
      const dateOfBirth = new Date(`${claims.birthdate}T12:00:00.000Z`);
      if (!Number.isFinite(dateOfBirth.getTime())) {
        response.status(422).json({ error: 'The verified PID contains an invalid birth date.' });
        return;
      }

      const firestore = getFirestore();
      const profileReference = firestore.collection('users').doc(user.uid);
      const alreadyAccepted = await firestore.runTransaction(async (transaction) => {
        const sessionReference = firestore
          .collection('pidVerificationSessions')
          .doc(sessionId);
        const sessionSnapshot = await transaction.get(sessionReference);
        const sessionData = sessionSnapshot.data();
        if (sessionData?.ownerUid !== user.uid) {
          throw new Error('PID verification session ownership changed.');
        }
        if (sessionData.state === 'accepted') {
          return true;
        }
        if (sessionData.state !== 'verified') {
          throw new HttpsError('failed-precondition', 'The session is closed.');
        }

        // Recheck the review deadline inside every transaction attempt.
        if (pidVerificationSessionResumableUntil(sessionData as Parameters<typeof pidVerificationSessionResumableUntil>[0]).getTime() <= Date.now()) {
          throw new HttpsError('deadline-exceeded', 'The session expired.');
        }
        const profileSnapshot = await transaction.get(profileReference);
        const nextIdentityRevision = pidIdentityRevision(profileSnapshot.data()) + 1;
        const verifiedAt = new Date();
        transaction.set(profileReference, {
          givenName: claims.givenName,
          surname: claims.familyName,
          dateOfBirth: Timestamp.fromDate(dateOfBirth),
          address: claims.formattedAddress,
          town: claims.locality,
          countryCode: claims.country!.toUpperCase(),
          isVerified: true,
          gotVerifiedAt: Timestamp.fromDate(verifiedAt),
          identityVerificationValidUntil: Timestamp.fromDate(
            pidIdentityVerificationValidUntil(verifiedAt),
          ),
          identityVerificationPolicyVersion:
            PID_IDENTITY_VERIFICATION_POLICY_VERSION,
          identityRevision: nextIdentityRevision,
          verifiedIdentityRevision: nextIdentityRevision,
          identityVerificationVerifiedFields: PID_IDENTITY_VERIFIED_FIELDS,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
        transaction.update(sessionReference, {
          state: 'accepted',
          updatedAt: FieldValue.serverTimestamp(),
          acceptedAt: FieldValue.serverTimestamp(),
        });
        return false;
      });

      response.json({ ok: true, alreadyAccepted, claims });
      logPidVerifierEvent({ traceId: persistedSession.traceId, event: 'session_accepted', outcome: 'success', status: 200, latencyMs: Date.now() - startedAt, validationOutcome: 'success', protocolStage: 'acceptance' });
    } catch (error) {
      if (error instanceof HttpsError && ['deadline-exceeded', 'failed-precondition'].includes(error.code)) {
        response.status(409).json({ code: error.code === 'deadline-exceeded' ? 'expired' : 'session_closed' });
        return;
      }
      const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
      if (status === 500) logPidVerifierEvent({
        event: 'operation_failed', outcome: 'failure', status,
        latencyMs: Date.now() - startedAt, errorCategory: pidVerifierErrorCategory(error),
        errorCode: 'acceptance_failed', protocolStage: 'acceptance',
      });
      response.status(status).json({
        error: status === 401 ? 'Authentication is required.' : 'The verified PID could not be saved.',
      });
    }
  });


  pidVerifierApp.post('/oid4vp/cancel/:sessionId', async (request, response) => {
    try {
      const user = await requireFirebaseUser(request);
      const session = await getOwnedPidVerificationSession(request.params.sessionId, user.uid);
      if (!session) {
        response.status(404).json({ code: 'session_not_found' });
        return;
      }
      await transitionPidVerificationSession(session.sessionId, 'cancelled');
      // An acceptance racing cancellation may already have committed. Report
      // the stored outcome instead of promising that saved data was discarded.
      const current = await getOwnedPidVerificationSession(session.sessionId, user.uid);
      response.json({ status: current?.state ?? session.state });
    } catch (error) {
      const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
      response.status(status).json({ code: status === 401 ? 'unauthenticated' : 'cancel_failed' });
    }
  });
}
