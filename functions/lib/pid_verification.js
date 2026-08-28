"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.pidVerificationRequestPreview = exports.pidVerifier = void 0;
const express_1 = __importDefault(require("express"));
const node_crypto_1 = require("node:crypto");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const https_1 = require("firebase-functions/v2/https");
const logger_1 = require("firebase-functions/logger");
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
const pidAccessCertificateSecret = (0, params_1.defineSecret)('PID_ACCESS_CERTIFICATE');
const pidAccessPrivateKeySecret = (0, params_1.defineSecret)('PID_ACCESS_PRIVATE_KEY');
const pidRegistrationCertificateSecret = (0, params_1.defineSecret)('PID_REGISTRATION_CERTIFICATE');
const PID_VERIFIER_BASE_URL = (_a = process.env.PID_VERIFIER_BASE_URL) !== null && _a !== void 0 ? _a : 'https://stimmapp-dev.web.app/oid4vp';
const PID_SANDBOX_TRUST_LIST_BASE_URL = 'https://bmi.usercontent.opencode.de/eudi-wallet/test-trust-lists';
let pidTrustListCache;
let pidTrustListPromise;
function decodeBase64UrlJson(value) {
    return JSON.parse(Buffer.from(value, 'base64url').toString('utf8'));
}
function pemCertificateBody(value) {
    return value
        .replace(/-----BEGIN CERTIFICATE-----/g, '')
        .replace(/-----END CERTIFICATE-----/g, '')
        .replace(/\s/g, '');
}
async function fetchPidSandboxTrustList() {
    var _a, _b, _c, _d;
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
    const signatureValid = (0, node_crypto_1.verify)('sha256', Buffer.from(`${parts[0]}.${parts[1]}`, 'ascii'), { key: signingCertificate, dsaEncoding: 'ieee-p1363' }, Buffer.from(parts[2], 'base64url'));
    if (!signatureValid) {
        throw new Error('The official EUDI sandbox PID trust-list signature is invalid.');
    }
    const payload = decodeBase64UrlJson(parts[1]);
    const listInformation = (_a = payload.LoTE) === null || _a === void 0 ? void 0 : _a.ListAndSchemeInformation;
    const issueTime = Date.parse((_b = listInformation === null || listInformation === void 0 ? void 0 : listInformation.ListIssueDateTime) !== null && _b !== void 0 ? _b : '');
    const nextUpdate = Date.parse((_c = listInformation === null || listInformation === void 0 ? void 0 : listInformation.NextUpdate) !== null && _c !== void 0 ? _c : '');
    const now = Date.now();
    if (!Number.isFinite(issueTime) || !Number.isFinite(nextUpdate) ||
        issueTime > now + 5 * 60 * 1000 || nextUpdate <= now) {
        throw new Error('The official EUDI sandbox PID trust list is not currently valid.');
    }
    const entities = (_d = payload.LoTE) === null || _d === void 0 ? void 0 : _d.TrustedEntitiesList;
    const certificates = Array.isArray(entities) ? entities.flatMap((entity) => {
        const services = entity === null || entity === void 0 ? void 0 : entity.TrustedEntityServices;
        if (!Array.isArray(services))
            return [];
        return services.flatMap((service) => {
            var _a;
            const information = service === null || service === void 0 ? void 0 : service.ServiceInformation;
            if ((information === null || information === void 0 ? void 0 : information.ServiceTypeIdentifier) !== 'http://uri.etsi.org/19602/SvcType/PID/Issuance') {
                return [];
            }
            const values = (_a = information === null || information === void 0 ? void 0 : information.ServiceDigitalIdentity) === null || _a === void 0 ? void 0 : _a.X509Certificates;
            if (!Array.isArray(values))
                return [];
            return values.map((certificate) => certificate === null || certificate === void 0 ? void 0 : certificate.val)
                .filter((certificate) => typeof certificate === 'string' && certificate.length > 0);
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
const pidVerifierApp = (0, express_1.default)();
pidVerifierApp.use(express_1.default.json());
pidVerifierApp.use(express_1.default.urlencoded({ extended: false }));
pidVerifierApp.use((request, response, next) => {
    if (!request.path.endsWith('/authorize')) {
        next();
        return;
    }
    let oauthError;
    const originalJson = response.json.bind(response);
    response.json = ((body) => {
        if (response.statusCode >= 400 && body && typeof body === 'object') {
            const value = body;
            oauthError = {
                error: value.error,
                error_description: value.error_description,
            };
        }
        return originalJson(body);
    });
    response.on('finish', () => {
        if (response.statusCode >= 400) {
            (0, logger_1.warn)('EUDI wallet response rejected.', {
                status: response.statusCode,
                error: typeof (oauthError === null || oauthError === void 0 ? void 0 : oauthError.error) === 'string' ? oauthError.error : undefined,
                errorDescription: typeof (oauthError === null || oauthError === void 0 ? void 0 : oauthError.error_description) === 'string' ?
                    oauthError.error_description : undefined,
                session: typeof request.query.session === 'string' ? request.query.session : undefined,
            });
        }
    });
    next();
});
let pidVerifierAgentPromise;
const pidVerificationSessionOwners = new Map();
// Credo's DCQL type is ESM-only while this Functions package is CommonJS.
// Keep this boundary untyped and validate it by creating a real request in the
// sandbox smoke test.
const pidDcql = {
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
                { path: ['address', 'region'] },
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
                getTrustedCertificatesForVerification: async (_agentContext, context) => {
                    var _a;
                    if (((_a = context === null || context === void 0 ? void 0 : context.verification) === null || _a === void 0 ? void 0 : _a.type) !== 'credential')
                        return undefined;
                    return getPidSandboxTrustCertificates();
                },
            }),
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
                app: pidVerifierApp,
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
        throw new https_1.HttpsError('failed-precondition', 'The EUDI verifier certificates are not configured.');
    }
    const privateJwk = (0, node_crypto_1.createPrivateKey)(accessPrivateKeyPem).export({ format: 'jwk' });
    const certificatePublicJwk = (0, node_crypto_1.createPublicKey)(accessCertificatePem).export({ format: 'jwk' });
    if (privateJwk.kty !== 'EC' || privateJwk.crv !== 'P-256' ||
        privateJwk.x !== certificatePublicJwk.x || privateJwk.y !== certificatePublicJwk.y) {
        throw new https_1.HttpsError('failed-precondition', 'The EUDI access certificate does not match the configured P-256 private key.');
    }
    const { keyId } = await agent.kms.importKey({ privateJwk: privateJwk });
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
async function createPidVerificationRequest(options, ownerUid) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
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
        authorizationResponseRedirectUri: (_a = options.returnUrl) !== null && _a !== void 0 ? _a : `${PID_VERIFIER_BASE_URL}/result/${(0, node_crypto_1.randomUUID)()}`,
    });
    const sessionInfo = verificationSession;
    const verificationSessionId = String((_d = (_c = (_b = sessionInfo.id) !== null && _b !== void 0 ? _b : sessionInfo.verificationSessionId) !== null && _c !== void 0 ? _c : sessionInfo.authorizationRequestId) !== null && _d !== void 0 ? _d : 'unknown-session');
    const state = (_f = (_e = sessionInfo.authorizationRequestPayload) === null || _e === void 0 ? void 0 : _e.state) !== null && _f !== void 0 ? _f : verificationSessionId;
    pidVerificationSessionOwners.set(verificationSessionId, {
        uid: ownerUid,
        expiresAt: (_h = (_g = verificationSession.expiresAt) === null || _g === void 0 ? void 0 : _g.getTime()) !== null && _h !== void 0 ? _h : Date.now() + 5 * 60 * 1000,
    });
    return {
        authorizationRequest,
        verificationSessionId,
        state,
        expiresAt: verificationSession.expiresAt ? verificationSession.expiresAt.toISOString() : new Date(Date.now() + 5 * 60 * 1000).toISOString(),
    };
}
async function requireFirebaseUser(request) {
    const authorization = request.header('authorization');
    if (!(authorization === null || authorization === void 0 ? void 0 : authorization.startsWith('Bearer '))) {
        throw new https_1.HttpsError('unauthenticated', 'Firebase authentication is required.');
    }
    return (0, auth_1.getAuth)().verifyIdToken(authorization.substring('Bearer '.length));
}
async function getVerifiedPidClaims(agent, sessionId) {
    var _a, _b, _c;
    const verified = await agent.openid4vc.verifier.getVerifiedAuthorizationResponse(sessionId);
    const presentation = (_c = (_b = (_a = verified.dcql) === null || _a === void 0 ? void 0 : _a.presentations) === null || _b === void 0 ? void 0 : _b['pid-sd-jwt']) === null || _c === void 0 ? void 0 : _c[0];
    const claims = presentation === null || presentation === void 0 ? void 0 : presentation.prettyClaims;
    const address = claims === null || claims === void 0 ? void 0 : claims.address;
    const streetAddress = typeof (address === null || address === void 0 ? void 0 : address.street_address) === 'string' ?
        address.street_address : null;
    const postalCode = typeof (address === null || address === void 0 ? void 0 : address.postal_code) === 'string' ?
        address.postal_code : null;
    const locality = typeof (address === null || address === void 0 ? void 0 : address.locality) === 'string' ? address.locality : null;
    const region = typeof (address === null || address === void 0 ? void 0 : address.region) === 'string' ? address.region : null;
    const country = typeof (address === null || address === void 0 ? void 0 : address.country) === 'string' ? address.country : null;
    const postalLocality = [postalCode, locality].filter(Boolean).join(' ');
    const formattedAddressParts = [streetAddress, postalLocality || null, country]
        .filter(Boolean);
    return {
        givenName: typeof (claims === null || claims === void 0 ? void 0 : claims.given_name) === 'string' ? claims.given_name : null,
        familyName: typeof (claims === null || claims === void 0 ? void 0 : claims.family_name) === 'string' ? claims.family_name : null,
        birthdate: typeof (claims === null || claims === void 0 ? void 0 : claims.birthdate) === 'string' ? claims.birthdate : null,
        streetAddress,
        postalCode,
        locality,
        region,
        country,
        formattedAddress: formattedAddressParts.length > 0 ?
            formattedAddressParts.join(', ') : null,
    };
}
pidVerifierApp.post('/oid4vp/start', async (request, response) => {
    var _a, _b;
    try {
        const user = await requireFirebaseUser(request);
        const mode = ((_a = request.body) === null || _a === void 0 ? void 0 : _a.mode) === 'reverification' ? 'reverification' : 'registration';
        const purpose = typeof ((_b = request.body) === null || _b === void 0 ? void 0 : _b.purpose) === 'string' ? request.body.purpose :
            mode === 'reverification' ? 'Periodic identity re-verification' : 'Registration verification';
        const result = await createPidVerificationRequest({ mode, purpose }, user.uid);
        response.json(Object.assign({ ok: true, mode, purpose }, result));
    }
    catch (error) {
        const status = error instanceof https_1.HttpsError && error.code === 'unauthenticated' ? 401 : 500;
        if (status === 500) {
            (0, logger_1.error)('Failed to create hosted PID verification request.', error);
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
        const owner = pidVerificationSessionOwners.get(sessionId);
        if (!owner || owner.uid !== user.uid) {
            response.status(404).json({ error: 'Verification session not found.' });
            return;
        }
        const { agent } = await ensurePidVerifierAgent();
        const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
        if (session.state === 'ResponseVerified') {
            response.json({
                status: 'verified',
                claims: await getVerifiedPidClaims(agent, sessionId),
            });
            return;
        }
        if (session.state === 'Error') {
            response.json({ status: 'failed', error: 'The PID presentation could not be verified.' });
            return;
        }
        if (owner.expiresAt <= Date.now()) {
            response.json({ status: 'expired' });
            return;
        }
        response.json({ status: 'pending' });
    }
    catch (error) {
        const status = error instanceof https_1.HttpsError && error.code === 'unauthenticated' ? 401 : 500;
        if (status === 500)
            (0, logger_1.error)('Failed to read PID verification status.', error);
        response.status(status).json({
            error: status === 401 ? 'Authentication is required.' : 'The PID verification status is unavailable.',
        });
    }
});
pidVerifierApp.post('/oid4vp/accept/:sessionId', async (request, response) => {
    try {
        const user = await requireFirebaseUser(request);
        const sessionId = request.params.sessionId;
        const owner = pidVerificationSessionOwners.get(sessionId);
        if (!owner || owner.uid !== user.uid) {
            response.status(404).json({ error: 'Verification session not found.' });
            return;
        }
        const { agent } = await ensurePidVerifierAgent();
        const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
        if (session.state !== 'ResponseVerified') {
            response.status(409).json({ error: 'The PID presentation has not been verified.' });
            return;
        }
        const claims = await getVerifiedPidClaims(agent, sessionId);
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
        await (0, firestore_1.getFirestore)().collection('users').doc(user.uid).set(Object.assign(Object.assign({ givenName: claims.givenName, surname: claims.familyName, dateOfBirth: firestore_1.Timestamp.fromDate(dateOfBirth), address: claims.formattedAddress, town: claims.locality }, (claims.region ? { state: claims.region } : {})), { countryCode: claims.country.toUpperCase(), isVerified: true, gotVerifiedAt: firestore_1.FieldValue.serverTimestamp(), updatedAt: firestore_1.FieldValue.serverTimestamp() }), { merge: true });
        response.json({ ok: true, claims });
    }
    catch (error) {
        const status = error instanceof https_1.HttpsError && error.code === 'unauthenticated' ? 401 : 500;
        if (status === 500)
            (0, logger_1.error)('Failed to accept verified PID credentials.', error);
        response.status(status).json({
            error: status === 401 ? 'Authentication is required.' : 'The verified PID could not be saved.',
        });
    }
});
pidVerifierApp.get('/oid4vp/result/:nonce', (_request, response) => {
    response.status(200).type('html').send('<!doctype html><html><body><h1>PID presentation received</h1>' +
        '<p>You can return to StimmApp.</p></body></html>');
});
const pidVerifierSecrets = [
    pidAccessCertificateSecret,
    pidAccessPrivateKeySecret,
    pidRegistrationCertificateSecret,
];
exports.pidVerifier = (0, https_1.onRequest)({ secrets: pidVerifierSecrets, maxInstances: 1, memory: '512MiB' }, async (request, response) => {
    try {
        await ensurePidVerifierAgent();
        pidVerifierApp(request, response);
    }
    catch (error) {
        (0, logger_1.error)('Failed to initialize hosted PID verifier.', error);
        response.status(500).json({ error: 'The PID verifier is not configured.' });
    }
});
exports.pidVerificationRequestPreview = {
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
//# sourceMappingURL=pid_verification.js.map