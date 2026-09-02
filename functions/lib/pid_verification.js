"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.pidVerificationRequestPreview = exports.pidVerifier = exports.pidVerifierApp = void 0;
exports.ensurePidVerifierAgent = ensurePidVerifierAgent;
exports.shutdownPidVerifierAgent = shutdownPidVerifierAgent;
const express_1 = __importDefault(require("express"));
const node_crypto_1 = require("node:crypto");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const https_1 = require("firebase-functions/v2/https");
const pid_claim_normalization_js_1 = require("./pid_claim_normalization.js");
const pid_identity_verification_policy_js_1 = require("./pid_identity_verification_policy.js");
const pid_verification_session_js_1 = require("./pid_verification_session.js");
const pid_verifier_runtime_config_js_1 = require("./pid_verifier_runtime_config.js");
const pid_verifier_logging_js_1 = require("./pid_verifier_logging.js");
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
const pidVerifierProxySharedSecret = (0, params_1.defineSecret)('PID_VERIFIER_PROXY_SHARED_SECRET');
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
exports.pidVerifierApp = (0, express_1.default)();
exports.pidVerifierApp.use(express_1.default.json());
exports.pidVerifierApp.use(express_1.default.urlencoded({ extended: false }));
exports.pidVerifierApp.use((request, response, next) => {
    if (!request.path.endsWith('/authorize')) {
        next();
        return;
    }
    response.on('finish', () => {
        if (response.statusCode >= 400) {
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
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
let pidVerifierAgentPromise;
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
                { path: ['address', 'country'] },
            ],
        },
    ],
};
async function initializePidVerifierAgent() {
    var _a;
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
                store: (0, pid_verifier_runtime_config_js_1.getPidAskarStoreConfig)(),
            }),
            openid4vc: new deps.OpenId4VcModule({
                // Credo currently carries its own Express type copy. Both values are
                // the same runtime API, but TypeScript cannot unify the declarations.
                app: exports.pidVerifierApp,
                verifier: {
                    baseUrl: PID_VERIFIER_BASE_URL,
                },
            }),
        },
    });
    await agent.initialize();
    const accessCertificatePem = (0, pid_verifier_runtime_config_js_1.readRuntimeSecret)({
        environmentName: 'PID_ACCESS_CERTIFICATE',
    });
    const accessPrivateKeyPem = (0, pid_verifier_runtime_config_js_1.readRuntimeSecret)({
        environmentName: 'PID_ACCESS_PRIVATE_KEY',
    });
    const registrationCertificate = (0, pid_verifier_runtime_config_js_1.readRuntimeSecret)({
        environmentName: 'PID_REGISTRATION_CERTIFICATE',
    });
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
    const verifierId = 'stimmapp-pid-verifier';
    const existingVerifiers = await agent.openid4vc.verifier.getAllVerifiers();
    const verifierRecord = (_a = existingVerifiers.find((record) => record.verifierId === verifierId)) !== null && _a !== void 0 ? _a : await agent.openid4vc.verifier.createVerifier({ verifierId });
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
async function shutdownPidVerifierAgent() {
    if (!pidVerifierAgentPromise)
        return;
    const { agent } = await pidVerifierAgentPromise;
    await agent.shutdown();
    pidVerifierAgentPromise = undefined;
}
async function createPidVerificationRequest(options, ownerUid) {
    var _a, _b, _c, _d, _e, _f;
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
        authorizationResponseRedirectUri: `${PID_VERIFIER_BASE_URL}/result/${(0, node_crypto_1.randomUUID)()}`,
    });
    const sessionInfo = verificationSession;
    const verificationSessionId = String((_c = (_b = (_a = sessionInfo.id) !== null && _a !== void 0 ? _a : sessionInfo.verificationSessionId) !== null && _b !== void 0 ? _b : sessionInfo.authorizationRequestId) !== null && _c !== void 0 ? _c : 'unknown-session');
    const state = (_e = (_d = sessionInfo.authorizationRequestPayload) === null || _d === void 0 ? void 0 : _d.state) !== null && _e !== void 0 ? _e : verificationSessionId;
    const expiresAt = (_f = verificationSession.expiresAt) !== null && _f !== void 0 ? _f : new Date(Date.now() + 5 * 60 * 1000);
    const traceId = await (0, pid_verification_session_js_1.createPidVerificationSession)({
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
function normalizeVerifiedPidClaimsForProfile(claims) {
    var _a, _b;
    const streetAddress = (0, pid_claim_normalization_js_1.normalizePidDisplayText)(claims.streetAddress);
    const postalCode = (0, pid_claim_normalization_js_1.normalizePidPostalCode)(claims.postalCode);
    const locality = (0, pid_claim_normalization_js_1.normalizePidDisplayText)(claims.locality);
    return {
        givenName: (0, pid_claim_normalization_js_1.normalizePidDisplayText)(claims.givenName),
        familyName: (0, pid_claim_normalization_js_1.normalizePidDisplayText)(claims.familyName),
        birthdate: claims.birthdate,
        streetAddress,
        postalCode,
        locality,
        region: (0, pid_claim_normalization_js_1.normalizePidDisplayText)(claims.region),
        country: (_b = (_a = claims.country) === null || _a === void 0 ? void 0 : _a.trim().toUpperCase()) !== null && _b !== void 0 ? _b : null,
        formattedAddress: (0, pid_claim_normalization_js_1.formatPidProfileAddress)({
            streetAddress,
            postalCode,
            locality,
        }),
    };
}
exports.pidVerifierApp.post('/oid4vp/start', async (request, response) => {
    const startedAt = Date.now();
    try {
        const user = await requireFirebaseUser(request);
        const profileSnapshot = await (0, firestore_1.getFirestore)().collection('users').doc(user.uid).get();
        const mode = (0, pid_identity_verification_policy_js_1.pidVerificationModeForProfile)(profileSnapshot.data());
        const purpose = mode === 'reverification' ?
            'Periodic identity re-verification' :
            'Registration verification';
        const result = await createPidVerificationRequest({ mode, purpose }, user.uid);
        (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
            traceId: result.traceId,
            event: 'request_created',
            outcome: 'success',
            latencyMs: Date.now() - startedAt,
            status: 200,
            validationOutcome: 'not_applicable',
            protocolStage: 'request_creation',
        });
        response.json(Object.assign({ ok: true, mode, purpose }, result));
    }
    catch (error) {
        const status = error instanceof https_1.HttpsError && error.code === 'unauthenticated' ? 401 : 500;
        if (status === 500) {
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
                event: 'operation_failed', outcome: 'failure', status,
                latencyMs: Date.now() - startedAt, errorCategory: (0, pid_verifier_logging_js_1.pidVerifierErrorCategory)(error),
                errorCode: 'request_creation_failed', protocolStage: 'request_creation',
            });
        }
        response.status(status).json({
            error: status === 401 ? 'Authentication is required.' : 'The PID verifier could not create a request.',
        });
    }
});
exports.pidVerifierApp.get('/oid4vp/resumable', async (request, response) => {
    const startedAt = Date.now();
    try {
        const user = await requireFirebaseUser(request);
        const session = await (0, pid_verification_session_js_1.getLatestResumablePidVerificationSession)(user.uid);
        response.json({
            session: session ? {
                sessionId: session.sessionId,
                status: session.state,
                mode: session.mode,
                purpose: session.purpose,
                expiresAt: (0, pid_verification_session_js_1.pidVerificationSessionResumableUntil)(session).toISOString(),
            } : null,
        });
    }
    catch (error) {
        const status = error instanceof https_1.HttpsError && error.code === 'unauthenticated' ? 401 : 500;
        if (status === 500)
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
                event: 'operation_failed', outcome: 'failure', status,
                latencyMs: Date.now() - startedAt, errorCategory: (0, pid_verifier_logging_js_1.pidVerifierErrorCategory)(error),
                errorCode: 'resumable_session_failed', protocolStage: 'status_check',
            });
        response.status(status).json({
            error: status === 401 ? 'Authentication is required.' :
                'The PID verification session could not be restored.',
        });
    }
});
exports.pidVerifierApp.get('/oid4vp/status/:sessionId', async (request, response) => {
    const startedAt = Date.now();
    try {
        const user = await requireFirebaseUser(request);
        const sessionId = request.params.sessionId;
        const persistedSession = await (0, pid_verification_session_js_1.getOwnedPidVerificationSession)(sessionId, user.uid);
        if (!persistedSession) {
            response.status(404).json({ error: 'Verification session not found.' });
            return;
        }
        if (persistedSession.state === 'failed') {
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({ traceId: persistedSession.traceId, event: 'session_failed', outcome: 'failure', status: 200, latencyMs: Date.now() - startedAt, errorCategory: 'validation', errorCode: 'previously_failed', validationOutcome: 'failure', protocolStage: 'status_check' });
            response.json({ status: 'failed', error: 'The PID presentation could not be verified.' });
            return;
        }
        if (persistedSession.state === 'accepted') {
            response.json({ status: 'accepted' });
            return;
        }
        if (persistedSession.state === 'expired' ||
            (0, pid_verification_session_js_1.pidVerificationSessionResumableUntil)(persistedSession).getTime() <= Date.now()) {
            await (0, pid_verification_session_js_1.transitionPidVerificationSession)(sessionId, 'expired');
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({ traceId: persistedSession.traceId, event: 'session_expired', outcome: 'failure', status: 200, latencyMs: Date.now() - startedAt, errorCategory: 'validation', errorCode: 'session_expired', validationOutcome: 'not_applicable', protocolStage: 'status_check' });
            response.json({ status: 'expired' });
            return;
        }
        const { agent } = await ensurePidVerifierAgent();
        const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
        if (session.state === 'ResponseVerified') {
            await (0, pid_verification_session_js_1.transitionPidVerificationSession)(sessionId, 'verified');
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({ traceId: persistedSession.traceId, event: 'session_verified', outcome: 'success', status: 200, latencyMs: Date.now() - startedAt, validationOutcome: 'success', protocolStage: 'status_check' });
            const claims = await getVerifiedPidClaims(agent, sessionId);
            response.json({
                status: 'verified',
                claims,
                normalizedClaims: normalizeVerifiedPidClaimsForProfile(claims),
            });
            return;
        }
        if (session.state === 'Error') {
            await (0, pid_verification_session_js_1.transitionPidVerificationSession)(sessionId, 'failed');
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({ traceId: persistedSession.traceId, event: 'session_failed', outcome: 'failure', status: 200, latencyMs: Date.now() - startedAt, errorCategory: 'validation', errorCode: 'presentation_verification_failed', validationOutcome: 'failure', protocolStage: 'status_check' });
            response.json({ status: 'failed', error: 'The PID presentation could not be verified.' });
            return;
        }
        response.json({ status: 'pending' });
    }
    catch (error) {
        const status = error instanceof https_1.HttpsError && error.code === 'unauthenticated' ? 401 : 500;
        if (status === 500)
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
                event: 'operation_failed', outcome: 'failure', status,
                latencyMs: Date.now() - startedAt, errorCategory: (0, pid_verifier_logging_js_1.pidVerifierErrorCategory)(error),
                errorCode: 'status_read_failed', protocolStage: 'status_check',
            });
        response.status(status).json({
            error: status === 401 ? 'Authentication is required.' : 'The PID verification status is unavailable.',
        });
    }
});
exports.pidVerifierApp.post('/oid4vp/accept/:sessionId', async (request, response) => {
    const startedAt = Date.now();
    try {
        const user = await requireFirebaseUser(request);
        const sessionId = request.params.sessionId;
        const persistedSession = await (0, pid_verification_session_js_1.getOwnedPidVerificationSession)(sessionId, user.uid);
        if (!persistedSession) {
            response.status(404).json({ error: 'Verification session not found.' });
            return;
        }
        if (persistedSession.state === 'accepted') {
            response.json({ ok: true, alreadyAccepted: true });
            return;
        }
        if ((0, pid_verification_session_js_1.pidVerificationSessionResumableUntil)(persistedSession).getTime() <= Date.now()) {
            await (0, pid_verification_session_js_1.transitionPidVerificationSession)(sessionId, 'expired');
            response.status(409).json({ error: 'The PID verification request expired.' });
            return;
        }
        const { agent } = await ensurePidVerifierAgent();
        const session = await agent.openid4vc.verifier.getVerificationSessionById(sessionId);
        if (session.state !== 'ResponseVerified') {
            response.status(409).json({ error: 'The PID presentation has not been verified.' });
            return;
        }
        await (0, pid_verification_session_js_1.transitionPidVerificationSession)(sessionId, 'verified');
        const claims = normalizeVerifiedPidClaimsForProfile(await getVerifiedPidClaims(agent, sessionId));
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
        const firestore = (0, firestore_1.getFirestore)();
        const profileReference = firestore.collection('users').doc(user.uid);
        let alreadyAccepted = false;
        await firestore.runTransaction(async (transaction) => {
            const sessionReference = firestore
                .collection('pidVerificationSessions')
                .doc(sessionId);
            const sessionSnapshot = await transaction.get(sessionReference);
            const sessionData = sessionSnapshot.data();
            if ((sessionData === null || sessionData === void 0 ? void 0 : sessionData.ownerUid) !== user.uid) {
                throw new Error('PID verification session ownership changed.');
            }
            if (sessionData.state === 'accepted') {
                alreadyAccepted = true;
                return;
            }
            if (sessionData.state !== 'verified') {
                throw new Error('PID verification session is not ready for acceptance.');
            }
            const profileSnapshot = await transaction.get(profileReference);
            const nextIdentityRevision = (0, pid_identity_verification_policy_js_1.pidIdentityRevision)(profileSnapshot.data()) + 1;
            const verifiedAt = new Date();
            transaction.set(profileReference, {
                givenName: claims.givenName,
                surname: claims.familyName,
                dateOfBirth: firestore_1.Timestamp.fromDate(dateOfBirth),
                address: claims.formattedAddress,
                town: claims.locality,
                countryCode: claims.country.toUpperCase(),
                isVerified: true,
                gotVerifiedAt: firestore_1.Timestamp.fromDate(verifiedAt),
                identityVerificationValidUntil: firestore_1.Timestamp.fromDate((0, pid_identity_verification_policy_js_1.pidIdentityVerificationValidUntil)(verifiedAt)),
                identityVerificationPolicyVersion: pid_identity_verification_policy_js_1.PID_IDENTITY_VERIFICATION_POLICY_VERSION,
                identityRevision: nextIdentityRevision,
                verifiedIdentityRevision: nextIdentityRevision,
                identityVerificationVerifiedFields: pid_identity_verification_policy_js_1.PID_IDENTITY_VERIFIED_FIELDS,
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
            transaction.update(sessionReference, {
                state: 'accepted',
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
                acceptedAt: firestore_1.FieldValue.serverTimestamp(),
            });
        });
        response.json({ ok: true, alreadyAccepted, claims });
        (0, pid_verifier_logging_js_1.logPidVerifierEvent)({ traceId: persistedSession.traceId, event: 'session_accepted', outcome: 'success', status: 200, latencyMs: Date.now() - startedAt, validationOutcome: 'success', protocolStage: 'acceptance' });
    }
    catch (error) {
        const status = error instanceof https_1.HttpsError && error.code === 'unauthenticated' ? 401 : 500;
        if (status === 500)
            (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
                event: 'operation_failed', outcome: 'failure', status,
                latencyMs: Date.now() - startedAt, errorCategory: (0, pid_verifier_logging_js_1.pidVerifierErrorCategory)(error),
                errorCode: 'acceptance_failed', protocolStage: 'acceptance',
            });
        response.status(status).json({
            error: status === 401 ? 'Authentication is required.' : 'The verified PID could not be saved.',
        });
    }
});
exports.pidVerifierApp.get('/oid4vp/result/:nonce', (_request, response) => {
    response.status(200).type('html').send('<!doctype html><html><body><h1>PID presentation received</h1>' +
        '<p>You can return to StimmApp.</p></body></html>');
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
/**
 * The Flutter web app can be served from either Firebase Hosting domain. It
 * calls the verifier through the other domain so that the OpenID4VP callback
 * URI is stable; therefore browser requests with an Authorization header need
 * an explicit preflight response before they reach the verifier or proxy.
 */
function applyPidVerifierCors(request, response) {
    var _a, _b, _c;
    const projectId = (_a = process.env.GCLOUD_PROJECT) !== null && _a !== void 0 ? _a : process.env.GCP_PROJECT;
    const configuredOrigins = (_c = (_b = process.env.PID_VERIFIER_ALLOWED_ORIGINS) === null || _b === void 0 ? void 0 : _b.split(',').map((origin) => origin.trim()).filter(Boolean)) !== null && _c !== void 0 ? _c : [];
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
    if (request.method !== 'OPTIONS')
        return false;
    if (requestOrigin && !allowedOrigins.has(requestOrigin)) {
        response.status(403).end();
        return true;
    }
    response.status(204).end();
    return true;
}
async function proxyPidVerifierRequest(request, response) {
    var _a, _b;
    const origin = (_a = process.env.PID_VERIFIER_ORIGIN_URL) === null || _a === void 0 ? void 0 : _a.trim().replace(/\/$/, '');
    if (!origin)
        return false;
    const headers = new Headers();
    for (const [name, value] of Object.entries(request.headers)) {
        if (proxyRequestHeadersToSkip.has(name.toLowerCase()) || value === undefined)
            continue;
        headers.set(name, Array.isArray(value) ? value.join(', ') : value);
    }
    headers.set('x-stimmapp-verifier-proxy', (0, pid_verifier_runtime_config_js_1.readRuntimeSecret)({ environmentName: 'PID_VERIFIER_PROXY_SHARED_SECRET' }));
    headers.set('x-forwarded-host', request.hostname);
    headers.set('x-forwarded-proto', request.protocol);
    const method = request.method.toUpperCase();
    const abortController = new AbortController();
    const abortTimer = setTimeout(() => abortController.abort(), 55000);
    let upstreamResponse;
    try {
        upstreamResponse = await fetch(`${origin}${request.originalUrl}`, {
            method,
            headers,
            redirect: 'manual',
            signal: abortController.signal,
            body: method === 'GET' || method === 'HEAD' ? undefined :
                ((_b = request.rawBody) !== null && _b !== void 0 ? _b : Buffer.alloc(0)),
        });
    }
    finally {
        clearTimeout(abortTimer);
    }
    upstreamResponse.headers.forEach((value, name) => {
        if (!proxyResponseHeadersToSkip.has(name.toLowerCase())) {
            response.setHeader(name, value);
        }
    });
    response.status(upstreamResponse.status).send(Buffer.from(await upstreamResponse.arrayBuffer()));
    return true;
}
exports.pidVerifier = (0, https_1.onRequest)({ secrets: pidVerifierSecrets, maxInstances: 1, memory: '512MiB' }, async (request, response) => {
    const startedAt = Date.now();
    try {
        if (applyPidVerifierCors(request, response))
            return;
        if (await proxyPidVerifierRequest(request, response))
            return;
        await ensurePidVerifierAgent();
        (0, exports.pidVerifierApp)(request, response);
    }
    catch (error) {
        (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
            event: 'operation_failed', outcome: 'failure', status: 500,
            latencyMs: Date.now() - startedAt, errorCategory: (0, pid_verifier_logging_js_1.pidVerifierErrorCategory)(error),
            errorCode: 'verifier_initialization_failed', protocolStage: 'initialization',
        });
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
        'address.country',
    ],
};
//# sourceMappingURL=pid_verification.js.map