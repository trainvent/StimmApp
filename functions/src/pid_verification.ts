import { pidResultPage } from './pid_verification_result_page.js';
import { registerPidSessionRoutes } from './pid_verification_routes.js';
import { getPidSandboxTrustedIssuers } from './pid_verifier_trust.js';
import { createPidSdJwtVcModule } from './pid_verifier_issuer.js';
import { createPidKeyManagementModule } from './pid_verifier_crypto.js';
import express from 'express';
import { createPrivateKey, createPublicKey, randomUUID } from 'node:crypto';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onRequest } from 'firebase-functions/v2/https';
import {
  formatPidProfileAddress,
  normalizePidDisplayText,
  normalizePidPostalCode,
} from './pid_claim_normalization.js';
import {
  pidVerificationModeForProfile,
} from './pid_identity_verification_policy.js';
import {
  PidVerificationMode,
  PidVerificationReturnTarget,
  createPidVerificationSession,
  getPidVerificationSessionByResultNonce,
} from './pid_verification_session.js';
import {
  getPidAskarStoreConfig,
  readRuntimeSecret,
} from './pid_verifier_runtime_config.js';
import {
  logPidVerifierEvent,
  pidVerifierErrorCategory,
} from './pid_verifier_logging.js';

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
    X509Module: coreModule.X509Module,
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
const pidVerifierProxySharedSecret = defineSecret('PID_VERIFIER_PROXY_SHARED_SECRET');

const PID_VERIFIER_BASE_URL = process.env.PID_VERIFIER_BASE_URL ??
  'https://stimmapp-dev.web.app/oid4vp';

export const pidVerifierApp = express();
// Every OpenID4VP endpoint is session- and user-specific. In particular, a
// status response must never be revalidated as 304 because the Flutter HTTP
// client receives an empty body and cannot deserialize the verification state.
pidVerifierApp.use((_request, response, next) => {
  response.setHeader('Cache-Control', 'no-store');
  next();
});
pidVerifierApp.use(express.json());
pidVerifierApp.use(express.urlencoded({ extended: false }));
pidVerifierApp.use((request, response, next) => {
  if (!request.path.endsWith('/authorize')) {
    next();
    return;
  }

  response.on('finish', () => {
    if (response.statusCode >= 400) {
      logPidVerifierEvent({
        event: 'wallet_response_rejected',
        outcome: 'rejected',
        status: response.statusCode,
        errorCategory: 'validation',
        errorCode: 'wallet_response_rejected',
        validationOutcome: 'failure',
        protocolStage: 'wallet_response',
      });
    }
  });

  next();
});

let pidVerifierAgentPromise: ReturnType<typeof initializePidVerifierAgent> | undefined;

type PidVerificationRequestInput = {
  mode: PidVerificationMode;
  purpose: string;
  returnTarget: PidVerificationReturnTarget;
  returnOrigin?: string;
};

type CreatePidVerificationRequestResult = {
  authorizationRequest: string;
  verificationSessionId: string;
  traceId: string;
  state: string;
  expiresAt: string;
};

export type VerifiedPidClaims = {
  givenName: string | null;
  familyName: string | null;
  birthdate: string | null;
  streetAddress: string | null;
  postalCode: string | null;
  locality: string | null;
  region: string | null;
  country: string | null;
  formattedAddress: string | null;
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
        { path: ['address', 'street_address'] },
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
    getTrustedIssuersForVerification: async (_agentContext: unknown, context: any) => {
      if (context.verification.type !== 'credential') return undefined;
      if (context.signer.method !== 'x509') return { trustedIssuers: [] };
      return { trustedIssuers: await getPidSandboxTrustedIssuers() };
    },
  };

  const agent = new deps.Agent({
    config,
    dependencies: deps.agentDependencies,
    modules: {
      kms: await createPidKeyManagementModule(),
      x509: new deps.X509Module(),
      askar: new deps.AskarModule({
        enableKms: false, // Registered explicitly alongside ES512 verification.
        askar: deps.askar,
        store: getPidAskarStoreConfig(),
      }),
      sdJwtVc: await createPidSdJwtVcModule(),
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

  const accessCertificatePem = readRuntimeSecret({
    environmentName: 'PID_ACCESS_CERTIFICATE',
  });
  const accessPrivateKeyPem = readRuntimeSecret({
    environmentName: 'PID_ACCESS_PRIVATE_KEY',
  });
  const registrationCertificate = readRuntimeSecret({
    environmentName: 'PID_REGISTRATION_CERTIFICATE',
  });
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

  const verifierId = 'stimmapp-pid-verifier';
  const existingVerifiers = await agent.openid4vc.verifier.getAllVerifiers();
  const verifierRecord = existingVerifiers.find(
    (record: { verifierId: string }) => record.verifierId === verifierId,
  ) ?? await agent.openid4vc.verifier.createVerifier({ verifierId });

  return {
    agent,
    accessCertificate,
    registrationCertificate,
    verifierRecord,
  };
}

export function ensurePidVerifierAgent() {
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

export async function shutdownPidVerifierAgent() {
  if (!pidVerifierAgentPromise) return;
  const { agent } = await pidVerifierAgentPromise;
  await agent.shutdown();
  pidVerifierAgentPromise = undefined;
}

async function createPidVerificationRequest(
  options: PidVerificationRequestInput,
  ownerUid: string,
): Promise<CreatePidVerificationRequestResult> {
  const { agent, accessCertificate, registrationCertificate, verifierRecord } = await ensurePidVerifierAgent();
  const resultNonce = randomUUID();

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
    authorizationResponseRedirectUri:
      `${PID_VERIFIER_BASE_URL}/result/${resultNonce}`,
  });

  const sessionInfo = verificationSession as any;
  const verificationSessionId = String(
    sessionInfo.id ?? sessionInfo.verificationSessionId ?? sessionInfo.authorizationRequestId ?? 'unknown-session',
  );
  const state = sessionInfo.authorizationRequestPayload?.state ?? verificationSessionId;
  const expiresAt = verificationSession.expiresAt ??
    new Date(Date.now() + 5 * 60 * 1000);
  const traceId = await createPidVerificationSession({
    sessionId: verificationSessionId,
    ownerUid,
    mode: options.mode,
    purpose: options.purpose,
    expiresAt,
    resultNonce,
    returnTarget: options.returnTarget,
    returnOrigin: options.returnOrigin,
  });

  return {
    authorizationRequest,
    verificationSessionId,
    traceId,
    state,
    expiresAt: expiresAt.toISOString(),
  };
}

async function requireFirebaseUser(request: express.Request) {
  const authorization = request.header('authorization');
  if (!authorization?.startsWith('Bearer ')) {
    throw new HttpsError('unauthenticated', 'Firebase authentication is required.');
  }
  try {
    return await getAuth().verifyIdToken(authorization.substring('Bearer '.length));
  } catch (_) {
    throw new HttpsError('unauthenticated', 'Firebase authentication is required.');
  }
}

async function getVerifiedPidClaims(agent: any, sessionId: string): Promise<VerifiedPidClaims> {
  const verified = await agent.openid4vc.verifier.getVerifiedAuthorizationResponse(sessionId);
  const presentation = verified.dcql?.presentations?.['pid-sd-jwt']?.[0];
  const claims = presentation?.prettyClaims;
  const address = claims?.address;
  const streetAddress = typeof address?.street_address === 'string' ?
    address.street_address : null;
  const postalCode = typeof address?.postal_code === 'string' ?
    address.postal_code : null;
  const locality = typeof address?.locality === 'string' ? address.locality : null;
  const region = typeof address?.region === 'string' ? address.region : null;
  const country = typeof address?.country === 'string' ? address.country : null;
  const postalLocality = [postalCode, locality].filter(Boolean).join(' ');
  const formattedAddressParts = [streetAddress, postalLocality || null, country]
    .filter(Boolean);
  return {
    givenName: typeof claims?.given_name === 'string' ? claims.given_name : null,
    familyName: typeof claims?.family_name === 'string' ? claims.family_name : null,
    birthdate: typeof claims?.birthdate === 'string' ? claims.birthdate : null,
    streetAddress,
    postalCode,
    locality,
    region,
    country,
    formattedAddress: formattedAddressParts.length > 0 ?
      formattedAddressParts.join(', ') : null,
  };
}

function normalizeVerifiedPidClaimsForProfile(
  claims: VerifiedPidClaims,
): VerifiedPidClaims {
  const streetAddress = normalizePidDisplayText(claims.streetAddress);
  const postalCode = normalizePidPostalCode(claims.postalCode);
  const locality = normalizePidDisplayText(claims.locality);
  return {
    givenName: normalizePidDisplayText(claims.givenName),
    familyName: normalizePidDisplayText(claims.familyName),
    birthdate: claims.birthdate,
    streetAddress,
    postalCode,
    locality,
    region: normalizePidDisplayText(claims.region),
    country: claims.country?.trim().toUpperCase() ?? null,
    formattedAddress: formatPidProfileAddress({
      streetAddress,
      postalCode,
      locality,
    }),
  };
}

pidVerifierApp.post('/oid4vp/start', async (request, response) => {
  const startedAt = Date.now();
  try {
    const user = await requireFirebaseUser(request);
    const profileSnapshot = await getFirestore().collection('users').doc(user.uid).get();
    const mode = pidVerificationModeForProfile(profileSnapshot.data());
    const purpose = mode === 'reverification' ?
      'Periodic identity re-verification' :
      'Registration verification';
    const returnTarget = request.body?.returnTarget === 'web' ? 'web' : 'native';
    const returnOrigin = returnTarget === 'web' ? allowedWebReturnOrigin(request) : undefined;
    const result = await createPidVerificationRequest(
      { mode, purpose, returnTarget, returnOrigin },
      user.uid,
    );
    logPidVerifierEvent({
      traceId: result.traceId,
      event: 'request_created',
      outcome: 'success',
      latencyMs: Date.now() - startedAt,
      status: 200,
      validationOutcome: 'not_applicable',
      protocolStage: 'request_creation',
    });
    response.json({ ok: true, mode, purpose, ...result });
  } catch (error) {
    const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
    if (status === 500) {
      logPidVerifierEvent({
        event: 'operation_failed', outcome: 'failure', status,
        latencyMs: Date.now() - startedAt, errorCategory: pidVerifierErrorCategory(error),
        errorCode: 'request_creation_failed', protocolStage: 'request_creation',
      });
    }
    response.status(status).json({
      error: status === 401 ? 'Authentication is required.' : 'The PID verifier could not create a request.',
    });
  }
});

registerPidSessionRoutes(pidVerifierApp, {
  requireFirebaseUser, ensurePidVerifierAgent, getVerifiedPidClaims,
  normalizeVerifiedPidClaimsForProfile,
});

function allowedWebReturnOrigin(request: express.Request) {
  const origin = request.header('origin');
  if (!origin) return undefined;
  const projectId = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT;
  const allowedOrigins = new Set([
    ...(projectId ? [
      `https://${projectId}.web.app`,
      `https://${projectId}.firebaseapp.com`,
    ] : []),
    ...(process.env.PID_VERIFIER_ALLOWED_ORIGINS?.split(',')
      .map((value) => value.trim())
      .filter(Boolean) ?? []),
  ]);
  return allowedOrigins.has(origin) ? origin : undefined;
}

function pidResultReturnUrl(session: {
  returnTarget: PidVerificationReturnTarget;
  returnOrigin?: string;
}) {
  if (session.returnTarget === 'native') return 'stimmapp://pid-verification';
  const origin = session.returnOrigin ?? PID_VERIFIER_BASE_URL.replace(/\/oid4vp$/, '');
  return `${origin}/pid-verification`;
}

pidVerifierApp.get('/oid4vp/result/:nonce', async (request, response) => {
  const session = await getPidVerificationSessionByResultNonce(request.params.nonce);
  const returnUrl = session ? pidResultReturnUrl(session) : 'stimmapp://pid-verification';
  response.status(200).type('html').send(pidResultPage(returnUrl, request.acceptsLanguages('en', 'de') === 'de' ? 'de' : 'en'));
});

const pidVerifierSecrets = [
  pidAccessCertificateSecret,
  pidAccessPrivateKeySecret,
  pidRegistrationCertificateSecret,
  pidVerifierProxySharedSecret,
];

const proxyRequestHeadersToSkip = new Set([
  'connection',
  'content-length',
  'host',
  'transfer-encoding',
]);

const proxyResponseHeadersToSkip = new Set([
  // The Firebase function owns caching rules so the external verifier cannot
  // re-enable HTTP validation for a session-specific response.
  'cache-control',
  'connection',
  'content-encoding',
  'content-length',
  'transfer-encoding',
]);

/**
 * The Flutter web app can be served from either Firebase Hosting domain. It
 * calls the verifier through the other domain so that the OpenID4VP callback
 * URI is stable; therefore browser requests with an Authorization header need
 * an explicit preflight response before they reach the verifier or proxy.
 */
function applyPidVerifierCors(request: express.Request, response: express.Response) {
  const projectId = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT;
  const configuredOrigins = process.env.PID_VERIFIER_ALLOWED_ORIGINS
    ?.split(',')
    .map((origin) => origin.trim())
    .filter(Boolean) ?? [];
  const allowedOrigins = new Set([
    ...(projectId ? [
      `https://${projectId}.web.app`,
      `https://${projectId}.firebaseapp.com`,
    ] : []),
    ...configuredOrigins,
  ]);
  const requestOrigin = request.header('origin');

  if (requestOrigin && allowedOrigins.has(requestOrigin)) {
    response.setHeader('Access-Control-Allow-Origin', requestOrigin);
    response.setHeader('Access-Control-Allow-Credentials', 'true');
    response.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    response.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.setHeader('Vary', 'Origin');
  }

  if (request.method !== 'OPTIONS') return false;
  if (requestOrigin && !allowedOrigins.has(requestOrigin)) {
    response.status(403).end();
    return true;
  }
  response.status(204).end();
  return true;
}

async function proxyPidVerifierRequest(
  request: express.Request & { rawBody?: Buffer },
  response: express.Response,
) {
  const origin = process.env.PID_VERIFIER_ORIGIN_URL?.trim().replace(/\/$/, '');
  if (!origin) return false;

  const headers = new Headers();
  for (const [name, value] of Object.entries(request.headers)) {
    if (proxyRequestHeadersToSkip.has(name.toLowerCase()) || value === undefined) continue;
    headers.set(name, Array.isArray(value) ? value.join(', ') : value);
  }
  headers.set(
    'x-stimmapp-verifier-proxy',
    readRuntimeSecret({ environmentName: 'PID_VERIFIER_PROXY_SHARED_SECRET' }),
  );
  headers.set('x-forwarded-host', request.hostname);
  headers.set('x-forwarded-proto', request.protocol);

  const method = request.method.toUpperCase();
  const abortController = new AbortController();
  const abortTimer = setTimeout(() => abortController.abort(), 55_000);
  let upstreamResponse: globalThis.Response;
  try {
    upstreamResponse = await fetch(`${origin}${request.originalUrl}`, {
      method,
      headers,
      redirect: 'manual',
      signal: abortController.signal,
      body: method === 'GET' || method === 'HEAD' ? undefined :
        (request.rawBody ?? Buffer.alloc(0)) as unknown as BodyInit,
    });
  } finally {
    clearTimeout(abortTimer);
  }

  upstreamResponse.headers.forEach((value, name) => {
    if (!proxyResponseHeadersToSkip.has(name.toLowerCase())) {
      response.setHeader(name, value);
    }
  });
  response.status(upstreamResponse.status).send(
    Buffer.from(await upstreamResponse.arrayBuffer()),
  );
  return true;
}

function isPidResultCallback(request: express.Request) {
  // This endpoint only reads the persisted callback session and renders the
  // return-to-app page. Keeping it at Firebase means an external verifier
  // image rollout cannot leave wallets on an obsolete result page.
  return request.method === 'GET' && /^\/oid4vp\/result\/[^/]+\/?$/.test(request.path);
}

export const pidVerifier = onRequest(
  { secrets: pidVerifierSecrets, maxInstances: 1, memory: '512MiB' },
  async (request, response) => {
    const startedAt = Date.now();
    try {
      response.setHeader('Cache-Control', 'no-store');
      if (applyPidVerifierCors(request, response)) return;
      if (isPidResultCallback(request)) {
        // Do not proxy or initialize Credo: the callback is deliberately
        // served by the Firebase edge from the Firestore-backed session.
        pidVerifierApp(request, response);
        return;
      }
      if (await proxyPidVerifierRequest(request, response)) return;
      await ensurePidVerifierAgent();
      pidVerifierApp(request, response);
    } catch (error) {
      logPidVerifierEvent({
        event: 'operation_failed', outcome: 'failure', status: 500,
        latencyMs: Date.now() - startedAt, errorCategory: pidVerifierErrorCategory(error),
        errorCode: 'verifier_initialization_failed', protocolStage: 'initialization',
      });
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
    'address.street_address',
    'address.postal_code',
    'address.locality',
    'address.country',
  ],
};
