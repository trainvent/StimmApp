import express from 'express';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

async function loadCredoDeps() {
  const [coreModule, nodeModule, askarModule, openidModule] = await Promise.all([
    import('@credo-ts/core'),
    import('@credo-ts/node'),
    import('@credo-ts/askar'),
    import('@credo-ts/openid4vc'),
  ]);

  return {
    Agent: coreModule.Agent,
    ConsoleLogger: coreModule.ConsoleLogger,
    DidKey: coreModule.DidKey,
    LogLevel: coreModule.LogLevel,
    TypedArrayEncoder: coreModule.TypedArrayEncoder,
    agentDependencies: nodeModule.agentDependencies,
    AskarModule: askarModule.AskarModule,
    askar: await import('@openwallet-foundation/askar-nodejs').then((module) => module.askar),
    transformPrivateKeyToPrivateJwk: askarModule.transformPrivateKeyToPrivateJwk,
    OpenId4VcModule: openidModule.OpenId4VcModule,
  };
}

const PID_VERIFIER_SECRET = process.env.PID_VERIFIER_SECRET ?? 'stimmapp-pid-verifier-secret-change-me';
const PID_VERIFIER_BASE_URL = process.env.PID_VERIFIER_BASE_URL ?? 'https://localhost/oid4vp';

const VERIFICATION_SESSION_STATE_INDEX = new Map<string, string>();

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
      format: 'vc+sd-jwt',
      meta: {
        vct_values: ['eu_eid_pid'],
      },
      claims: [
        { path: ['given_name'] },
        { path: ['family_name'] },
        { path: ['birth_date'] },
        { path: ['date_of_birth'] },
        { path: ['person_identifier'] },
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

async function ensurePidVerifierAgent() {
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

  const { privateJwk } = deps.transformPrivateKeyToPrivateJwk({
    type: {
      crv: 'Ed25519',
      kty: 'OKP',
    },
    privateKey: deps.TypedArrayEncoder.fromUtf8String(PID_VERIFIER_SECRET),
  });

  const { keyId } = await agent.kms.importKey({ privateJwk });
  const didCreateResult = await agent.dids.create({
    method: 'key',
    options: { keyId },
  } as any);

  const did = didCreateResult.didState.did as string;
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

  const result = await createPidVerificationRequest({
    mode,
    purpose,
    returnUrl: typeof request.data?.returnUrl === 'string' ? request.data.returnUrl : undefined,
  });

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
  attributes: [
    'given_name',
    'family_name',
    'birth_date',
    'date_of_birth',
    'person_identifier',
  ],
};
