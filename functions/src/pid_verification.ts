import express from 'express';
import { createPrivateKey, createPublicKey, randomUUID } from 'node:crypto';
import { getAuth } from 'firebase-admin/auth';
import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onRequest } from 'firebase-functions/v2/https';
import { error as logError } from 'firebase-functions/logger';

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
    LogLevel: coreModule.LogLevel,
    X509Certificate: coreModule.X509Certificate,
    agentDependencies: nodeModule.agentDependencies,
    AskarModule: askarModule.AskarModule,
    askar: nativeAskarModule.askar,
    OpenId4VcModule: openidModule.OpenId4VcModule,
  };
}

const pidAccessCertificateSecret = defineSecret('PID_ACCESS_CERTIFICATE');
const pidAccessPrivateKeySecret = defineSecret('PID_ACCESS_PRIVATE_KEY');
const pidRegistrationCertificateSecret = defineSecret('PID_REGISTRATION_CERTIFICATE');

const PID_VERIFIER_BASE_URL = process.env.PID_VERIFIER_BASE_URL ??
  'https://stimmapp-dev.web.app/oid4vp';

const pidVerifierApp = express();
pidVerifierApp.use(express.json());
pidVerifierApp.use(express.urlencoded({ extended: false }));

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
        { path: ['address', 'postal_code'] },
        { path: ['address', 'locality'] },
        { path: ['address', 'country'] },
      ],
    },
  ],
};

async function initializePidVerifierAgent() {
  const deps = await loadCredoDeps();
  const config = {
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
        // Credo currently carries its own Express type copy. Both values are
        // the same runtime API, but TypeScript cannot unify the declarations.
        app: pidVerifierApp as any,
        verifier: {
          baseUrl: PID_VERIFIER_BASE_URL,
        },
      }),
    },
  });

  await agent.initialize();

  const accessCertificatePem = pidAccessCertificateSecret.value().trim();
  const accessPrivateKeyPem = pidAccessPrivateKeySecret.value().trim();
  const registrationCertificate = pidRegistrationCertificateSecret.value().trim();
  if (!accessCertificatePem || !accessPrivateKeyPem || !registrationCertificate) {
    throw new HttpsError('failed-precondition', 'The EUDI verifier certificates are not configured.');
  }

  const privateJwk = createPrivateKey(accessPrivateKeyPem).export({ format: 'jwk' });
  const certificatePublicJwk = createPublicKey(accessCertificatePem).export({ format: 'jwk' });
  if (privateJwk.kty !== 'EC' || privateJwk.crv !== 'P-256' ||
      privateJwk.x !== certificatePublicJwk.x || privateJwk.y !== certificatePublicJwk.y) {
    throw new HttpsError(
      'failed-precondition',
      'The EUDI access certificate does not match the configured P-256 private key.',
    );
  }

  const { keyId } = await agent.kms.importKey({ privateJwk: privateJwk as any });
  const accessCertificate = deps.X509Certificate.fromEncodedCertificate(accessCertificatePem);
  accessCertificate.keyId = keyId;

  const verifierRecord = await agent.openid4vc.verifier.createVerifier({
    verifierId: 'stimmapp-pid-verifier',
  });

  return {
    agent,
    accessCertificate,
    registrationCertificate,
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
  const { agent, accessCertificate, registrationCertificate, verifierRecord } = await ensurePidVerifierAgent();

  const { authorizationRequest, verificationSession } = await agent.openid4vc.verifier.createAuthorizationRequest({
    requestSigner: {
      method: 'x5c',
      x5c: [accessCertificate],
      clientIdPrefix: 'x509_hash',
    },
    verifierId: verifierRecord.verifierId,
    verifierInfo: [
      {
        format: 'registration_cert',
        data: registrationCertificate,
        credential_ids: ['pid-sd-jwt'],
      },
    ],
    version: 'v1',
    dcql: {
      query: pidDcql,
    },
    responseMode: 'direct_post.jwt',
    authorizationResponseRedirectUri: options.returnUrl ??
      `${PID_VERIFIER_BASE_URL}/result/${randomUUID()}`,
  });

  const sessionInfo = verificationSession as any;
  const verificationSessionId = String(
    sessionInfo.id ?? sessionInfo.verificationSessionId ?? sessionInfo.authorizationRequestId ?? 'unknown-session',
  );
  const state = sessionInfo.authorizationRequestPayload?.state ?? verificationSessionId;

  return {
    authorizationRequest,
    verificationSessionId,
    state,
    expiresAt: verificationSession.expiresAt ? verificationSession.expiresAt.toISOString() : new Date(Date.now() + 5 * 60 * 1000).toISOString(),
  };
}

async function requireFirebaseUser(request: express.Request) {
  const authorization = request.header('authorization');
  if (!authorization?.startsWith('Bearer ')) {
    throw new HttpsError('unauthenticated', 'Firebase authentication is required.');
  }
  return getAuth().verifyIdToken(authorization.substring('Bearer '.length));
}

pidVerifierApp.post('/oid4vp/start', async (request, response) => {
  try {
    await requireFirebaseUser(request);
    const mode = request.body?.mode === 'reverification' ? 'reverification' : 'registration';
    const purpose = typeof request.body?.purpose === 'string' ? request.body.purpose :
      mode === 'reverification' ? 'Periodic identity re-verification' : 'Registration verification';
    const result = await createPidVerificationRequest({ mode, purpose });
    response.json({ ok: true, mode, purpose, ...result });
  } catch (error) {
    const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
    if (status === 500) {
      logError('Failed to create hosted PID verification request.', error);
    }
    response.status(status).json({
      error: status === 401 ? 'Authentication is required.' : 'The PID verifier could not create a request.',
    });
  }
});

pidVerifierApp.get('/oid4vp/result/:nonce', (_request, response) => {
  response.status(200).type('html').send(
    '<!doctype html><html><body><h1>PID presentation received</h1>' +
    '<p>You can return to StimmApp.</p></body></html>',
  );
});

const pidVerifierSecrets = [
  pidAccessCertificateSecret,
  pidAccessPrivateKeySecret,
  pidRegistrationCertificateSecret,
];

export const pidVerifier = onRequest(
  { secrets: pidVerifierSecrets, maxInstances: 1, memory: '512MiB' },
  async (request, response) => {
    try {
      await ensurePidVerifierAgent();
      pidVerifierApp(request, response);
    } catch (error) {
      logError('Failed to initialize hosted PID verifier.', error);
      response.status(500).json({ error: 'The PID verifier is not configured.' });
    }
  },
);

export const pidVerificationRequestPreview = {
  mode: 'registration',
  purpose: 'Register a user by verifying their German PID attributes.',
  recommendedFormat: 'SD-JWT VC',
  credentialFormat: 'dc+sd-jwt',
  credentialType: 'urn:eudi:pid:de:1',
  attributes: [
    'given_name',
    'family_name',
    'birthdate',
    'address.postal_code',
    'address.locality',
    'address.country',
  ],
};
