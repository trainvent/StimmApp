import express from 'express';
import { createHash } from 'node:crypto';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { error as logError, warn as logWarning } from 'firebase-functions/logger';

async function loadCredoDeps() {
  const [coreModule, nodeModule, askarModule, openidModule, nativeAskarModule] = await Promise.all([
    import('@credo-ts/core'),
    import('@credo-ts/node'),
    import('@credo-ts/askar'),
    import('@credo-ts/openid4vc'),
    // Load the native implementation alongside the Askar adapter. Loading it
    // later can leave the adapter bound to an unregistered native singleton.
    import('@openwallet-foundation/askar-nodejs'),
  ]);

  return {
    Agent: coreModule.Agent,
    ConsoleLogger: coreModule.ConsoleLogger,
    DidKey: coreModule.DidKey,
    LogLevel: coreModule.LogLevel,
    TypedArrayEncoder: coreModule.TypedArrayEncoder,
    agentDependencies: nodeModule.agentDependencies,
    AskarModule: askarModule.AskarModule,
    askar: nativeAskarModule.askar,
    transformPrivateKeyToPrivateJwk: askarModule.transformPrivateKeyToPrivateJwk,
    OpenId4VcModule: openidModule.OpenId4VcModule,
  };
}

const PID_VERIFIER_SECRET = process.env.PID_VERIFIER_SECRET ?? 'stimmapp-pid-verifier-secret-change-me';
const PID_VERIFIER_BASE_URL = process.env.PID_VERIFIER_BASE_URL ?? 'https://localhost/oid4vp';

const VERIFICATION_SESSION_STATE_INDEX = new Map<string, string>();
let pidVerifierAgentPromise: ReturnType<typeof initializePidVerifierAgent> | undefined;

type PidVerificationMode = 'registration' | 'reverification';

type PidVerificationRequestInput = {
  mode?: PidVerificationMode;
  purpose?: string;
  returnUrl?: string;
};

type CreatePidVerificationRequestResult = {
  authorizationRequest: string;
  verificationSessionId: string;
  state: string;
  expiresAt: string;
};

type VerifyPidVerificationResponseInput = {
  verificationSessionId: string;
  authorizationResponse: Record<string, unknown>;
};

type VerifiedPidPresentation = {
  verified: Record<string, unknown>;
  pidClaims: Record<string, unknown>;
  verificationSessionId: string;
};

// Credo's DCQL type is ESM-only while this Functions package is CommonJS.
// Keep this boundary untyped and validate it by creating a real request in the
// sandbox smoke test.
const pidDcql: any = {
  credential_sets: [
    {
      required: true,
      options: [['pid-sd-jwt']],
    },
  ],
  credentials: [
    {
      id: 'pid-sd-jwt',
      format: 'dc+sd-jwt',
      meta: {
        vct_values: ['urn:eudi:pid:de:1'],
      },
      claims: [
        { path: ['given_name'] },
        { path: ['family_name'] },
        { path: ['birthdate'] },
      ],
    },
  ],
};

function decodePidClaimsFromVerifiedResponse(value: Record<string, unknown>): Record<string, unknown> {
  const targetKeys = new Set([
    'given_name',
    'family_name',
    'birth_date',
    'date_of_birth',
    'person_identifier',
    'address',
    'nationality',
    'name',
    'full_name',
    'birthdate',
  ]);
  const found: Record<string, unknown> = {};

  const walk = (node: unknown) => {
    if (!node || typeof node !== 'object') {
      return;
    }

    if (Array.isArray(node)) {
      for (const item of node) {
        walk(item);
      }
      return;
    }

    for (const [key, nestedValue] of Object.entries(node as Record<string, unknown>)) {
      if (targetKeys.has(key)) {
        found[key] = nestedValue;
      }
      walk(nestedValue);
    }
  };

  walk(value);
  return found;
}

/**
 * Credo expects an Ed25519 seed to contain exactly 32 bytes. Environment
 * secrets are arbitrary-length strings, so passing their UTF-8 bytes directly
 * makes Askar fail with "Invalid key data".
 */
function deriveVerifierPrivateKey(secret: string): Uint8Array {
  return new Uint8Array(createHash('sha256').update(secret, 'utf8').digest());
}

async function initializePidVerifierAgent() {
  const deps = await loadCredoDeps();
  const app = express() as any;
  const config = {
    allowInsecureHttpUrls: true,
    logger: new deps.ConsoleLogger(deps.LogLevel.Off),
  };

  const agent = new deps.Agent({
    config,
    dependencies: deps.agentDependencies,
    modules: {
      askar: new deps.AskarModule({
        askar: deps.askar,
        store: {
          id: 'stimmapp-pid-verifier-store',
          key: 'stimmapp-pid-verifier-key',
          // Cloud Functions only guarantees that /tmp is writable. An
          // in-memory store also avoids stale/locked SQLite files between
          // requests in a warm instance.
          database: {
            type: 'sqlite',
            config: { inMemory: true },
          },
        },
      }),
      openid4vc: new deps.OpenId4VcModule({
        app,
        verifier: {
          baseUrl: PID_VERIFIER_BASE_URL,
        },
      }),
    },
  });

  await agent.initialize();

  if (!process.env.PID_VERIFIER_SECRET) {
    logWarning(
      'PID_VERIFIER_SECRET is not configured; using the sandbox fallback. ' +
      'Do not use this verifier identity in production.',
    );
  }

  const { privateJwk } = deps.transformPrivateKeyToPrivateJwk({
    type: {
      crv: 'Ed25519',
      kty: 'OKP',
    },
    privateKey: deriveVerifierPrivateKey(PID_VERIFIER_SECRET),
  });

  const { keyId } = await agent.kms.importKey({ privateJwk });
  const didCreateResult = await agent.dids.create({
    method: 'key',
    options: { keyId },
  } as any);

  const did = didCreateResult.didState.did;
  if (!did) {
    throw new HttpsError(
      'internal',
      `Unable to create verifier DID: ${JSON.stringify(didCreateResult.didState)}`,
    );
  }
  const didKey = deps.DidKey.fromDid(did);
  const kid = `${did}#${didKey.publicJwk.fingerprint}`;
  const verificationMethod = didCreateResult.didState.didDocument?.dereferenceKey(kid, ['authentication']);

  if (!verificationMethod) {
    throw new HttpsError('internal', 'Unable to resolve verifier DID verification method.');
  }

  const verifierRecord = await agent.openid4vc.verifier.createVerifier({
    verifierId: 'stimmapp-pid-verifier',
  });

  return {
    agent,
    verificationMethod,
    verifierRecord,
  };
}

function ensurePidVerifierAgent() {
  if (!pidVerifierAgentPromise) {
    pidVerifierAgentPromise = initializePidVerifierAgent().catch((error) => {
      // Permit a later invocation to recover from a transient initialization
      // failure instead of retaining a rejected promise for the instance.
      pidVerifierAgentPromise = undefined;
      throw error;
    });
  }

  return pidVerifierAgentPromise;
}

async function createPidVerificationRequest(options: PidVerificationRequestInput): Promise<CreatePidVerificationRequestResult> {
  const { agent, verificationMethod, verifierRecord } = await ensurePidVerifierAgent();

  const { authorizationRequest, verificationSession } = await agent.openid4vc.verifier.createAuthorizationRequest({
    requestSigner: {
      method: 'did',
      didUrl: verificationMethod.id,
    },
    verifierId: verifierRecord.verifierId,
    dcql: {
      query: pidDcql,
    },
    responseMode: 'direct_post.jwt',
    authorizationResponseRedirectUri: options.returnUrl ?? `${PID_VERIFIER_BASE_URL}/callback`,
  });

  const sessionInfo = verificationSession as any;
  const verificationSessionId = String(
    sessionInfo.id ?? sessionInfo.verificationSessionId ?? sessionInfo.authorizationRequestId ?? 'unknown-session',
  );
  const state = sessionInfo.authorizationRequestPayload?.state ?? verificationSessionId;

  VERIFICATION_SESSION_STATE_INDEX.set(state, verificationSessionId);

  return {
    authorizationRequest,
    verificationSessionId,
    state,
    expiresAt: verificationSession.expiresAt ? verificationSession.expiresAt.toISOString() : new Date(Date.now() + 5 * 60 * 1000).toISOString(),
  };
}

async function verifyPidAuthorizationResponse(input: VerifyPidVerificationResponseInput): Promise<VerifiedPidPresentation> {
  const { agent } = await ensurePidVerifierAgent();
  const verified = await agent.openid4vc.verifier.verifyAuthorizationResponse({
    verificationSessionId: input.verificationSessionId,
    authorizationResponse: input.authorizationResponse,
  });

  const pidClaims = decodePidClaimsFromVerifiedResponse(verified as unknown as Record<string, unknown>);

  return {
    verified: verified as unknown as Record<string, unknown>,
    pidClaims,
    verificationSessionId: input.verificationSessionId,
  };
}

export const createPidVerificationRequestCallable = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Authentication is required to start PID verification.');
  }

  const mode = (request.data?.mode as PidVerificationMode | undefined) ?? 'registration';
  const purpose = typeof request.data?.purpose === 'string' ? request.data.purpose :
    mode === 'reverification'
      ? 'Periodic identity re-verification'
      : 'Registration verification';

  let result: CreatePidVerificationRequestResult;
  try {
    result = await createPidVerificationRequest({
      mode,
      purpose,
      returnUrl: typeof request.data?.returnUrl === 'string' ? request.data.returnUrl : undefined,
    });
  } catch (error) {
    logError('Failed to create PID verification request.', error);
    throw new HttpsError(
      'internal',
      'The PID verifier could not create a request. Check the verifier configuration and retry.',
    );
  }

  return {
    ok: true,
    mode,
    purpose,
    ...result,
  };
});

export const verifyPidVerificationResponseCallable = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Authentication is required to verify the wallet presentation.');
  }

  const verificationSessionId = typeof request.data?.verificationSessionId === 'string'
    ? request.data.verificationSessionId
    : undefined;

  const authorizationResponse = typeof request.data?.authorizationResponse === 'object' && request.data.authorizationResponse !== null
    ? request.data.authorizationResponse as Record<string, unknown>
    : undefined;

  if (!verificationSessionId || !authorizationResponse) {
    throw new HttpsError('invalid-argument', 'verificationSessionId and authorizationResponse are required.');
  }

  const result = await verifyPidAuthorizationResponse({
    verificationSessionId,
    authorizationResponse,
  });

  return {
    ok: true,
    ...result,
  };
});

export const pidVerificationRequestPreview = {
  mode: 'registration',
  purpose: 'Register a user by verifying their German PID attributes.',
  recommendedFormat: 'SD-JWT VC',
  credentialFormat: 'dc+sd-jwt',
  credentialType: 'urn:eudi:pid:de:1',
  attributes: ['given_name', 'family_name', 'birthdate'],
};
