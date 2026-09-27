"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PID_PREPROD_ISSUER = void 0;
exports.createPidIssuerKeyResolver = createPidIssuerKeyResolver;
exports.createPidSdJwtVcModule = createPidSdJwtVcModule;
const node_async_hooks_1 = require("node:async_hooks");
const node_crypto_1 = require("node:crypto");
exports.PID_PREPROD_ISSUER = 'https://preprod.pid-provider.bundesdruckerei.de';
// This is an additional binding, never a replacement for signed-list X.509
// trust. Do not follow arbitrary credential URLs or metadata redirects.
function createPidIssuerKeyResolver(fetchMetadata = fetch) {
    let cached;
    let pending;
    return async (issuer, certificate) => {
        if (issuer !== exports.PID_PREPROD_ISSUER)
            return false;
        const key = new node_crypto_1.X509Certificate(Buffer.from(certificate, 'base64')).publicKey
            .export({ type: 'spki', format: 'der' }).toString('base64');
        if (!cached || cached.until <= Date.now()) {
            pending !== null && pending !== void 0 ? pending : (pending = (async () => {
                var _a;
                const response = await fetchMetadata(`${exports.PID_PREPROD_ISSUER}/.well-known/jwt-vc-issuer`, {
                    redirect: 'error', signal: AbortSignal.timeout(10000),
                });
                if (!response.ok)
                    throw new Error('PID issuer metadata unavailable.');
                const metadata = await response.json();
                if (metadata.issuer !== exports.PID_PREPROD_ISSUER || !Array.isArray((_a = metadata.jwks) === null || _a === void 0 ? void 0 : _a.keys)) {
                    throw new Error('PID issuer metadata invalid.');
                }
                const keys = metadata.jwks.keys.filter((jwk) => jwk.kty === 'EC' && jwk.crv === 'P-256' &&
                    (!jwk.use || jwk.use === 'sig') && (!jwk.alg || jwk.alg === 'ES256'))
                    .map((jwk) => (0, node_crypto_1.createPublicKey)({ key: jwk, format: 'jwk' })
                    .export({ type: 'spki', format: 'der' }).toString('base64'));
                cached = { keys, until: Date.now() + 5 * 60 * 1000 };
                return keys;
            })().finally(() => { pending = undefined; }));
            await pending;
        }
        return cached.keys.includes(key);
    };
}
// Credo 0.7.1 has no public issuer-name-policy hook. Keep this compatibility
// adapter on this agent's service instance (not the SDK prototype), guarded by
// version and method checks. Remove it when upstream exposes an equivalent hook.
// AsyncLocalStorage confines the additional binding to its own verify call;
// signing, other issuers and concurrent verifications retain the SDK policy.
async function createPidSdJwtVcModule(resolveIssuerKey = createPidIssuerKeyResolver()) {
    const { SdJwtVcModule, SdJwtVcService } = await import('@credo-ts/core');
    if (require('@credo-ts/core/package.json').version !== '0.7.1') {
        throw new Error('Review PID issuer binding adapter for this Credo version.');
    }
    const binding = new node_async_hooks_1.AsyncLocalStorage();
    const installed = new WeakSet();
    return new class extends SdJwtVcModule {
        async onInitializeContext(context) {
            const service = context.resolve(SdJwtVcService);
            if (installed.has(service))
                return;
            installed.add(service);
            // Explicit boundary to the pinned SDK's private synchronous name check.
            const internal = service;
            if (typeof internal.assertValidX5cJwtIssuer !== 'function') {
                throw new Error('PID issuer binding adapter is incompatible with Credo.');
            }
            const originalNameCheck = internal.assertValidX5cJwtIssuer.bind(service);
            internal.assertValidX5cJwtIssuer = (context, issuer, leaf) => {
                const verifiedBinding = binding.getStore();
                if ((verifiedBinding === null || verifiedBinding === void 0 ? void 0 : verifiedBinding.issuer) === issuer && verifiedBinding.certificate === leaf.toString('base64'))
                    return;
                return originalNameCheck(context, issuer, leaf);
            };
            const originalVerify = service.verify.bind(service);
            service.verify = async (context, options) => {
                // No mutation of JWTs, decoded claims, certificates, or verification
                // options. Credo still checks chain trust, signatures, status and KB-JWT.
                let allowed;
                try {
                    const [headerPart, payloadPart] = options.compactSdJwtVc.split('.');
                    const header = JSON.parse(Buffer.from(headerPart, 'base64url').toString());
                    const payload = JSON.parse(Buffer.from(payloadPart, 'base64url').toString());
                    if (header.typ === 'dc+sd-jwt' && payload.vct === 'urn:eudi:pid:de:1' &&
                        payload.iss === exports.PID_PREPROD_ISSUER && Array.isArray(header.x5c) && header.x5c.length) {
                        const leaf = new node_crypto_1.X509Certificate(Buffer.from(header.x5c[0], 'base64'));
                        // A present but mismatching SAN must still fail the ordinary check.
                        if (!leaf.subjectAltName && await resolveIssuerKey(payload.iss, header.x5c[0])) {
                            allowed = { issuer: payload.iss, certificate: leaf.raw.toString('base64') };
                        }
                    }
                }
                catch (_a) {
                    // Fail closed through the original name check on malformed input or
                    // metadata outage; never turn an unverified issuer into a trusted one.
                }
                return binding.run(allowed, () => originalVerify(context, options));
            };
        }
    }();
}
//# sourceMappingURL=pid_verifier_issuer.js.map