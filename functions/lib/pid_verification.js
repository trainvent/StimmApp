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
const pidVerifierApp = (0, express_1.default)();
pidVerifierApp.use(express_1.default.json());
pidVerifierApp.use(express_1.default.urlencoded({ extended: false }));
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
async function createPidVerificationRequest(options) {
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
        authorizationResponseRedirectUri: (_a = options.returnUrl) !== null && _a !== void 0 ? _a : `${PID_VERIFIER_BASE_URL}/result/${(0, node_crypto_1.randomUUID)()}`,
    });
    const sessionInfo = verificationSession;
    const verificationSessionId = String((_d = (_c = (_b = sessionInfo.id) !== null && _b !== void 0 ? _b : sessionInfo.verificationSessionId) !== null && _c !== void 0 ? _c : sessionInfo.authorizationRequestId) !== null && _d !== void 0 ? _d : 'unknown-session');
    const state = (_f = (_e = sessionInfo.authorizationRequestPayload) === null || _e === void 0 ? void 0 : _e.state) !== null && _f !== void 0 ? _f : verificationSessionId;
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
pidVerifierApp.post('/oid4vp/start', async (request, response) => {
    var _a, _b;
    try {
        await requireFirebaseUser(request);
        const mode = ((_a = request.body) === null || _a === void 0 ? void 0 : _a.mode) === 'reverification' ? 'reverification' : 'registration';
        const purpose = typeof ((_b = request.body) === null || _b === void 0 ? void 0 : _b.purpose) === 'string' ? request.body.purpose :
            mode === 'reverification' ? 'Periodic identity re-verification' : 'Registration verification';
        const result = await createPidVerificationRequest({ mode, purpose });
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
        'address.postal_code',
        'address.locality',
        'address.country',
    ],
};
//# sourceMappingURL=pid_verification.js.map