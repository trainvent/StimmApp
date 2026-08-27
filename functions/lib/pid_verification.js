"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a, _b;
Object.defineProperty(exports, "__esModule", { value: true });
exports.pidVerificationRequestPreview = exports.verifyPidVerificationResponseCallable = exports.createPidVerificationRequestCallable = void 0;
const express_1 = __importDefault(require("express"));
const node_crypto_1 = require("node:crypto");
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
const PID_VERIFIER_SECRET = (_a = process.env.PID_VERIFIER_SECRET) !== null && _a !== void 0 ? _a : 'stimmapp-pid-verifier-secret-change-me';
const PID_VERIFIER_BASE_URL = (_b = process.env.PID_VERIFIER_BASE_URL) !== null && _b !== void 0 ? _b : 'https://localhost/oid4vp';
const VERIFICATION_SESSION_STATE_INDEX = new Map();
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
            ],
        },
    ],
};
function decodePidClaimsFromVerifiedResponse(value) {
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
    const found = {};
    const walk = (node) => {
        if (!node || typeof node !== 'object') {
            return;
        }
        if (Array.isArray(node)) {
            for (const item of node) {
                walk(item);
            }
            return;
        }
        for (const [key, nestedValue] of Object.entries(node)) {
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
function deriveVerifierPrivateKey(secret) {
    return new Uint8Array((0, node_crypto_1.createHash)('sha256').update(secret, 'utf8').digest());
}
async function initializePidVerifierAgent() {
    var _a;
    const deps = await loadCredoDeps();
    const app = (0, express_1.default)();
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
        (0, logger_1.warn)('PID_VERIFIER_SECRET is not configured; using the sandbox fallback. ' +
            'Do not use this verifier identity in production.');
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
    });
    const did = didCreateResult.didState.did;
    if (!did) {
        throw new https_1.HttpsError('internal', `Unable to create verifier DID: ${JSON.stringify(didCreateResult.didState)}`);
    }
    const didKey = deps.DidKey.fromDid(did);
    const kid = `${did}#${didKey.publicJwk.fingerprint}`;
    const verificationMethod = (_a = didCreateResult.didState.didDocument) === null || _a === void 0 ? void 0 : _a.dereferenceKey(kid, ['authentication']);
    if (!verificationMethod) {
        throw new https_1.HttpsError('internal', 'Unable to resolve verifier DID verification method.');
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
async function createPidVerificationRequest(options) {
    var _a, _b, _c, _d, _e, _f;
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
        authorizationResponseRedirectUri: (_a = options.returnUrl) !== null && _a !== void 0 ? _a : `${PID_VERIFIER_BASE_URL}/callback`,
    });
    const sessionInfo = verificationSession;
    const verificationSessionId = String((_d = (_c = (_b = sessionInfo.id) !== null && _b !== void 0 ? _b : sessionInfo.verificationSessionId) !== null && _c !== void 0 ? _c : sessionInfo.authorizationRequestId) !== null && _d !== void 0 ? _d : 'unknown-session');
    const state = (_f = (_e = sessionInfo.authorizationRequestPayload) === null || _e === void 0 ? void 0 : _e.state) !== null && _f !== void 0 ? _f : verificationSessionId;
    VERIFICATION_SESSION_STATE_INDEX.set(state, verificationSessionId);
    return {
        authorizationRequest,
        verificationSessionId,
        state,
        expiresAt: verificationSession.expiresAt ? verificationSession.expiresAt.toISOString() : new Date(Date.now() + 5 * 60 * 1000).toISOString(),
    };
}
async function verifyPidAuthorizationResponse(input) {
    const { agent } = await ensurePidVerifierAgent();
    const verified = await agent.openid4vc.verifier.verifyAuthorizationResponse({
        verificationSessionId: input.verificationSessionId,
        authorizationResponse: input.authorizationResponse,
    });
    const pidClaims = decodePidClaimsFromVerifiedResponse(verified);
    return {
        verified: verified,
        pidClaims,
        verificationSessionId: input.verificationSessionId,
    };
}
exports.createPidVerificationRequestCallable = (0, https_1.onCall)(async (request) => {
    var _a, _b, _c, _d;
    const auth = request.auth;
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'Authentication is required to start PID verification.');
    }
    const mode = (_b = (_a = request.data) === null || _a === void 0 ? void 0 : _a.mode) !== null && _b !== void 0 ? _b : 'registration';
    const purpose = typeof ((_c = request.data) === null || _c === void 0 ? void 0 : _c.purpose) === 'string' ? request.data.purpose :
        mode === 'reverification'
            ? 'Periodic identity re-verification'
            : 'Registration verification';
    let result;
    try {
        result = await createPidVerificationRequest({
            mode,
            purpose,
            returnUrl: typeof ((_d = request.data) === null || _d === void 0 ? void 0 : _d.returnUrl) === 'string' ? request.data.returnUrl : undefined,
        });
    }
    catch (error) {
        (0, logger_1.error)('Failed to create PID verification request.', error);
        throw new https_1.HttpsError('internal', 'The PID verifier could not create a request. Check the verifier configuration and retry.');
    }
    return Object.assign({ ok: true, mode,
        purpose }, result);
});
exports.verifyPidVerificationResponseCallable = (0, https_1.onCall)(async (request) => {
    var _a, _b;
    const auth = request.auth;
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'Authentication is required to verify the wallet presentation.');
    }
    const verificationSessionId = typeof ((_a = request.data) === null || _a === void 0 ? void 0 : _a.verificationSessionId) === 'string'
        ? request.data.verificationSessionId
        : undefined;
    const authorizationResponse = typeof ((_b = request.data) === null || _b === void 0 ? void 0 : _b.authorizationResponse) === 'object' && request.data.authorizationResponse !== null
        ? request.data.authorizationResponse
        : undefined;
    if (!verificationSessionId || !authorizationResponse) {
        throw new https_1.HttpsError('invalid-argument', 'verificationSessionId and authorizationResponse are required.');
    }
    const result = await verifyPidAuthorizationResponse({
        verificationSessionId,
        authorizationResponse,
    });
    return Object.assign({ ok: true }, result);
});
exports.pidVerificationRequestPreview = {
    mode: 'registration',
    purpose: 'Register a user by verifying their German PID attributes.',
    recommendedFormat: 'SD-JWT VC',
    credentialFormat: 'dc+sd-jwt',
    credentialType: 'urn:eudi:pid:de:1',
    attributes: ['given_name', 'family_name', 'birthdate'],
};
//# sourceMappingURL=pid_verification.js.map