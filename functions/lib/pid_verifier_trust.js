"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parsePidTrustedIssuers = parsePidTrustedIssuers;
exports.getPidSandboxTrustedIssuers = getPidSandboxTrustedIssuers;
const node_crypto_1 = require("node:crypto");
// Parse only after the signed list and its validity window have been verified.
function parsePidTrustedIssuers(payload) {
    var _a;
    const entities = (_a = payload.LoTE) === null || _a === void 0 ? void 0 : _a.TrustedEntitiesList;
    const issuers = Array.isArray(entities) ? entities.flatMap((entity) => {
        const services = entity === null || entity === void 0 ? void 0 : entity.TrustedEntityServices;
        if (!Array.isArray(services))
            return [];
        const certificates = (type) => [...new Set(services.flatMap((service) => {
                var _a;
                const info = service === null || service === void 0 ? void 0 : service.ServiceInformation;
                if ((info === null || info === void 0 ? void 0 : info.ServiceTypeIdentifier) !== `http://uri.etsi.org/19602/SvcType/PID/${type}`)
                    return [];
                const values = (_a = info === null || info === void 0 ? void 0 : info.ServiceDigitalIdentity) === null || _a === void 0 ? void 0 : _a.X509Certificates;
                return Array.isArray(values) ? values.map((cert) => cert === null || cert === void 0 ? void 0 : cert.val)
                    .filter((cert) => typeof cert === 'string' && cert.length > 0) : [];
            }))];
        const issuance = certificates('Issuance');
        const status = certificates('Revocation');
        return issuance.length ? [Object.assign({ method: 'x509', issuance }, (status.length ? { status } : {}))] : [];
    }) : [];
    if (!issuers.length)
        throw new Error('The official EUDI sandbox PID trust list contains no PID issuance certificates.');
    return issuers;
}
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
    var _a, _b, _c;
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
    const issuers = parsePidTrustedIssuers(payload);
    return {
        issuers,
        // Refresh before the signed list expires, but avoid downloading it for
        // each verification handled by a warm Cloud Functions instance.
        validUntil: Math.min(nextUpdate - 5 * 60 * 1000, now + 60 * 60 * 1000),
    };
}
async function getPidSandboxTrustedIssuers() {
    if (pidTrustListCache && pidTrustListCache.validUntil > Date.now()) {
        return pidTrustListCache.issuers;
    }
    if (!pidTrustListPromise) {
        pidTrustListPromise = fetchPidSandboxTrustList()
            .then((result) => (pidTrustListCache = result))
            .finally(() => {
            pidTrustListPromise = undefined;
        });
    }
    return (await pidTrustListPromise).issuers;
}
//# sourceMappingURL=pid_verifier_trust.js.map