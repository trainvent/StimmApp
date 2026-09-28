"use strict";
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.pidPresentationFailureCode = pidPresentationFailureCode;
exports.summarizePidSession = summarizePidSession;
exports.diagnosePidRequest = diagnosePidRequest;
const pid_verifier_runtime_config_js_1 = require("./pid_verifier_runtime_config.js");
// Stored Credo errors can contain claims, tokens, URLs, and key material.
// Never print them, even in the sandbox. Match known SDK messages to constants.
function pidPresentationFailureCode(message) {
    var _a, _b;
    if (typeof message !== 'string' || !message)
        return 'no_stored_error';
    const knownErrors = [
        ['No trusted certificate was found while validating the X.509 chain', 'issuer_chain_untrusted'],
        ['The status list certificate chain could not be validated against the trusted status certificates.', 'status_list_trust_failed'],
        ['The status list signer chain does not match the credential issuer chain, and no dedicated trusted status certificates were configured for the trusted issuer.', 'status_list_dedicated_trust_missing'],
        ['The key binding JWT does not contain the expected audience', 'holder_audience_mismatch'],
        ['The key binding JWT does not contain the expected nonce', 'holder_nonce_mismatch'],
        ['Keybinding is required for verification of the sd-jwt-vc', 'holder_binding_missing'],
        ['No trusted certificates configured for X509 certificate chain validation.', 'issuer_trust_missing'],
        ['The official EUDI sandbox PID trust list is not currently valid.', 'trust_list_expired'],
        ['The official EUDI sandbox PID trust list could not be downloaded.', 'trust_list_download_failed'],
        ['The official EUDI sandbox PID trust-list signature is invalid.', 'trust_list_signature_invalid'],
        ["The 'iss' claim in the payload does not match", 'issuer_certificate_name_mismatch'],
        ['session expired', 'session_expired'],
    ];
    return (_b = (_a = knownErrors.find(([text]) => message.includes(text))) === null || _a === void 0 ? void 0 : _a[1]) !== null && _b !== void 0 ? _b : 'unclassified_verification_failure';
}
function summarizePidSession(record) {
    const states = ['RequestCreated', 'RequestUriRetrieved', 'ResponseVerified', 'Error'];
    return {
        state: typeof record.state === 'string' && states.includes(record.state) ? record.state : 'unknown',
        failureCode: pidPresentationFailureCode(record.errorMessage),
    };
}
async function diagnosePidRequest(requestId) {
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(requestId)) {
        throw new Error('invalid_request_id');
    }
    // Open the existing store directly: no agent initialization, provisioning,
    // migrations, new requests, verification replay, or Firestore writes.
    const { Store } = await import('@openwallet-foundation/askar-nodejs');
    const config = (0, pid_verifier_runtime_config_js_1.getPidAskarStoreConfig)();
    const db = config.database;
    const uri = db.type === 'postgres' ?
        `postgres://${encodeURIComponent(db.credentials.account)}:${encodeURIComponent(db.credentials.password)}` +
            `@${db.config.host}/${encodeURIComponent(config.id)}?connect_timeout=10&max_connections=1&min_connections=0` :
        `sqlite://${db.config.path}`;
    const store = await Store.open({ uri, passKey: config.key });
    try {
        const session = await store.session().open();
        try {
            const records = await session.fetchAll({
                category: 'OpenId4VcVerificationSessionRecord',
                tagFilter: { authorizationRequestId: requestId },
                limit: 2,
                isJson: true,
                forUpdate: false,
            });
            if (records.length !== 1)
                return { result: records.length ? 'ambiguous_request' : 'request_not_found' };
            const value = records[0].value;
            const record = typeof value === 'string' ? JSON.parse(value) : value;
            return Object.assign({ result: 'found' }, summarizePidSession(record));
        }
        finally {
            await session.close();
        }
    }
    finally {
        await store.close();
    }
}
if (require.main === module) {
    diagnosePidRequest((_a = process.argv[2]) !== null && _a !== void 0 ? _a : '').then((result) => {
        console.log(JSON.stringify(result));
    }).catch(() => {
        // In particular, do not print connection errors containing the store URI.
        console.error(JSON.stringify({ result: 'diagnostic_failed' }));
        process.exitCode = 1;
    });
}
//# sourceMappingURL=pid_verifier_diagnose.js.map