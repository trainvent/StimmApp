import express from 'express';
import { createPrivateKey, createPublicKey, randomUUID, verify as verifySignature } from 'node:crypto';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, Timestamp, getFirestore } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import { HttpsError, onRequest } from 'firebase-functions/v2/https';
import { error as logError, warn as logWarning } from 'firebase-functions/logger';
import {
  formatPidProfileAddress,
  normalizePidDisplayText,
  normalizePidPostalCode,
} from './pid_claim_normalization.js';
import {
  PidVerificationMode,
  createPidVerificationSession,
  getOwnedPidVerificationSession,
  transitionPidVerificationSession,
} from './pid_verification_session.js';
import {
  getPidAskarStoreConfig,
  readRuntimeSecret,
} from './pid_verifier_runtime_config.js';

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
const PID_SANDBOX_TRUST_LIST_BASE_URL =
  'https://bmi.usercontent.opencode.de/eudi-wallet/test-trust-lists';

type PidTrustListCache = {
  certificates: string[];
  validUntil: number;
};

let pidTrustListCache: PidTrustListCache | undefined;
let pidTrustListPromise: Promise<PidTrustListCache> | undefined;

function decodeBase64UrlJson(value: string): Record<string, any> {
  return JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as Record<string, any>;
}

function pemCertificateBody(value: string) {
  return value
    .replace(/-----BEGIN CERTIFICATE-----/g, '')
    .replace(/-----END CERTIFICATE-----/g, '')
    .replace(/\s/g, '');
}

async function fetchPidSandboxTrustList(): Promise<PidTrustListCache> {
  const [trustListResponse, signingCertificateResponse] = await Promise.all([
    fetch(`${PID_SANDBOX_TRUST_LIST_BASE_URL}/pid-provider.jwt`),
    fetch(`${PID_SANDBOX_TRUST_LIST_BASE_URL}/certificate.pem`),
  ]);
  if (!trustListResponse.ok || !signingCertificateResponse.ok) {
    throw new Error('The official EUDI sandbox PID trust list could not be downloaded.');
  }

  const compactJwt = (await trustListResponse.text()).trim();
  const signingCertificate = (await signingCertificateResponse.text()).trim();
  const parts = compactJwt.split('.');
  if (parts.length !== 3) {
    throw new Error('The official EUDI sandbox PID trust list is not a compact JWT.');
  }

  const header = decodeBase64UrlJson(parts[0]);
  if (header.alg !== 'ES256' || header.typ !== 'trustlist+jwt' ||
      !Array.isArray(header.x5c) || header.x5c[0] !== pemCertificateBody(signingCertificate)) {
    throw new Error('The official EUDI sandbox PID trust-list signer is invalid.');
  }

  const signatureValid = verifySignature(
    'sha256',
    Buffer.from(`${parts[0]}.${parts[1]}`, 'ascii'),
    { key: signingCertificate, dsaEncoding: 'ieee-p1363' },
    Buffer.from(parts[2], 'base64url'),
  );
  if (!signatureValid) {
    throw new Error('The official EUDI sandbox PID trust-list signature is invalid.');
  }

  const payload = decodeBase64UrlJson(parts[1]);
  const listInformation = payload.LoTE?.ListAndSchemeInformation;
  const issueTime = Date.parse(listInformation?.ListIssueDateTime ?? '');
  const nextUpdate = Date.parse(listInformation?.NextUpdate ?? '');
  const now = Date.now();
  if (!Number.isFinite(issueTime) || !Number.isFinite(nextUpdate) ||
      issueTime > now + 5 * 60 * 1000 || nextUpdate <= now) {
    throw new Error('The official EUDI sandbox PID trust list is not currently valid.');
  }

  const entities = payload.LoTE?.TrustedEntitiesList;
  const certificates = Array.isArray(entities) ? entities.flatMap((entity: any) => {
    const services = entity?.TrustedEntityServices;
    if (!Array.isArray(services)) return [];
    return services.flatMap((service: any) => {
      const information = service?.ServiceInformation;
      if (information?.ServiceTypeIdentifier !== 'http://uri.etsi.org/19602/SvcType/PID/Issuance') {
        return [];
      }
      const values = information?.ServiceDigitalIdentity?.X509Certificates;
      if (!Array.isArray(values)) return [];
      return values.map((certificate: any) => certificate?.val)
        .filter((certificate: unknown): certificate is string =>
          typeof certificate === 'string' && certificate.length > 0);
    });
  }) : [];
  const uniqueCertificates = [...new Set(certificates)];
  if (uniqueCertificates.length === 0) {
    throw new Error('The official EUDI sandbox PID trust list contains no PID issuance certificates.');
  }

  return {
    certificates: uniqueCertificates,
    // Refresh before the signed list expires, but avoid downloading it for
    // each verification handled by a warm Cloud Functions instance.
    validUntil: Math.min(nextUpdate - 5 * 60 * 1000, now + 60 * 60 * 1000),
  };
}

async function getPidSandboxTrustCertificates() {
  if (pidTrustListCache && pidTrustListCache.validUntil > Date.now()) {
    return pidTrustListCache.certificates;
  }
  if (!pidTrustListPromise) {
    pidTrustListPromise = fetchPidSandboxTrustList()
      .then((result) => (pidTrustListCache = result))
      .finally(() => {
        pidTrustListPromise = undefined;
      });
  }
  return (await pidTrustListPromise).certificates;
}

export const pidVerifierApp = express();
pidVerifierApp.use(express.json());
pidVerifierApp.use(express.urlencoded({ extended: false }));
pidVerifierApp.use((request, response, next) => {
  if (!request.path.endsWith('/authorize')) {
    next();
    return;
  }

  let oauthError: { error?: unknown; error_description?: unknown } | undefined;
  const originalJson = response.json.bind(response);
  response.json = ((body: unknown) => {
    if (response.statusCode >= 400 && body && typeof body === 'object') {
      const value = body as Record<string, unknown>;
      oauthError = {
        error: value.error,
        error_description: value.error_description,
      };
    }
    return originalJson(body);
  }) as typeof response.json;

  response.on('finish', () => {
    if (response.statusCode >= 400) {
      logWarning('EUDI wallet response rejected.', {
        status: response.statusCode,
        error: typeof oauthError?.error === 'string' ? oauthError.error : undefined,
        errorDescription: typeof oauthError?.error_description === 'string' ?
          oauthError.error_description : undefined,
        session: typeof request.query.session === 'string' ? request.query.session : undefined,
      });
    }
  });

  next();
});

let pidVerifierAgentPromise: ReturnType<typeof initializePidVerifierAgent> | undefined;

type PidVerificationRequestInput = {
  mode: PidVerificationMode;
  purpose: string;
};

type CreatePidVerificationRequestResult = {
  authorizationRequest: string;
  verificationSessionId: string;
  traceId: string;
  state: string;
  expiresAt: string;
};

type VerifiedPidClaims = {
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
  };

  const agent = new deps.Agent({
    config,
    dependencies: deps.agentDependencies,
    modules: {
      x509: new deps.X509Module({
        getTrustedCertificatesForVerification: async (_agentContext: unknown, context: any) => {
          if (context?.verification?.type !== 'credential') return undefined;
          return getPidSandboxTrustCertificates();
        },
      }),
      askar: new deps.AskarModule({
        askar: deps.askar,
        store: getPidAskarStoreConfig(),
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
      `${PID_VERIFIER_BASE_URL}/result/${randomUUID()}`,
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
  return getAuth().verifyIdToken(authorization.substring('Bearer '.length));
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
  try {
    const user = await requireFirebaseUser(request);
    const mode = request.body?.mode === 'reverification' ? 'reverification' : 'registration';
    const purpose = mode === 'reverification' ?
      'Periodic identity re-verification' :
      'Registration verification';
    const result = await createPidVerificationRequest({ mode, purpose }, user.uid);
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

pidVerifierApp.get('/oid4vp/status/:sessionId', async (request, response) => {
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

    if (persistedSession.state === 'failed') {
      response.json({ status: 'failed', error: 'The PID presentation could not be verified.' });
      return;
    }
    if (persistedSession.state === 'expired' ||
        persistedSession.expiresAt.toMillis() <= Date.now()) {
      await transitionPidVerificationSession(sessionId, 'expired');
      response.json({ status: 'expired' });
      return;
    }

    const { agent } = await ensurePidVerifierAgent();
    const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
    if (session.state === 'ResponseVerified') {
      await transitionPidVerificationSession(sessionId, 'verified');
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
      response.json({ status: 'failed', error: 'The PID presentation could not be verified.' });
      return;
    }
    response.json({ status: 'pending' });
  } catch (error) {
    const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
    if (status === 500) logError('Failed to read PID verification status.', error);
    response.status(status).json({
      error: status === 401 ? 'Authentication is required.' : 'The PID verification status is unavailable.',
    });
  }
});

pidVerifierApp.post('/oid4vp/accept/:sessionId', async (request, response) => {
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
    if (persistedSession.expiresAt.toMillis() <= Date.now()) {
      await transitionPidVerificationSession(sessionId, 'expired');
      response.status(409).json({ error: 'The PID verification request expired.' });
      return;
    }

    const { agent } = await ensurePidVerifierAgent();
    const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
    if (session.state !== 'ResponseVerified') {
      response.status(409).json({ error: 'The PID presentation has not been verified.' });
      return;
    }
    await transitionPidVerificationSession(sessionId, 'verified');

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

    await getFirestore().collection('users').doc(user.uid).set({
      givenName: claims.givenName,
      surname: claims.familyName,
      dateOfBirth: Timestamp.fromDate(dateOfBirth),
      address: claims.formattedAddress,
      town: claims.locality,
      ...(claims.region ? { state: claims.region } : {}),
      countryCode: claims.country.toUpperCase(),
      isVerified: true,
      gotVerifiedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    await transitionPidVerificationSession(sessionId, 'accepted');

    response.json({ ok: true, claims });
  } catch (error) {
    const status = error instanceof HttpsError && error.code === 'unauthenticated' ? 401 : 500;
    if (status === 500) logError('Failed to accept verified PID credentials.', error);
    response.status(status).json({
      error: status === 401 ? 'Authentication is required.' : 'The verified PID could not be saved.',
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
  pidVerifierProxySharedSecret,
];

const proxyRequestHeadersToSkip = new Set([
  'connection',
  'content-length',
  'host',
  'transfer-encoding',
]);

const proxyResponseHeadersToSkip = new Set([
  'connection',
  'content-encoding',
  'content-length',
  'transfer-encoding',
]);

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

export const pidVerifier = onRequest(
  { secrets: pidVerifierSecrets, maxInstances: 1, memory: '512MiB' },
  async (request, response) => {
    try {
      if (await proxyPidVerifierRequest(request, response)) return;
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
    'address.street_address',
    'address.postal_code',
    'address.locality',
    'address.region',
    'address.country',
  ],
};
