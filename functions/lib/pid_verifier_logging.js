"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logPidVerifierEvent = logPidVerifierEvent;
exports.pidVerifierErrorCategory = pidVerifierErrorCategory;
const node_crypto_1 = require("node:crypto");
function logEnvironment() {
    var _a, _b;
    const configured = (_a = process.env.PID_VERIFIER_LOG_ENV) === null || _a === void 0 ? void 0 : _a.trim();
    if (configured === 'production' || configured === 'sandbox')
        return configured;
    return ((_b = process.env.GCLOUD_PROJECT) === null || _b === void 0 ? void 0 : _b.trim()) === 'stimmapp-f0141' ?
        'production' : 'sandbox';
}
/**
 * Emits one JSON record with a fixed, privacy-safe schema. Do not add request
 * bodies, tokens, claims, wallet identifiers, certificates, session IDs, or
 * error objects here: production and sandbox share the same data boundary.
 */
function logPidVerifierEvent(input, write = (record) => {
    console.log(JSON.stringify(record));
}) {
    var _a, _b, _c;
    const record = {
        timestamp: new Date().toISOString(),
        traceId: (_a = input.traceId) !== null && _a !== void 0 ? _a : (0, node_crypto_1.randomUUID)(),
        event: input.event,
        outcome: input.outcome,
        invocationMethod: (_b = input.invocationMethod) !== null && _b !== void 0 ? _b : 'same-device',
        validationOutcome: (_c = input.validationOutcome) !== null && _c !== void 0 ? _c : 'not_applicable',
    };
    if (typeof input.latencyMs === 'number')
        record.latencyMs = Math.max(0, Math.round(input.latencyMs));
    if (typeof input.status === 'number')
        record.status = input.status;
    if (input.errorCategory)
        record.errorCategory = input.errorCategory;
    if (input.errorCode)
        record.errorCode = input.errorCode;
    // Sandbox is allowed a small extra diagnostic enum; it never gets protocol data.
    if (logEnvironment() === 'sandbox' && input.protocolStage) {
        record.protocolStage = input.protocolStage;
    }
    write(record);
    return record;
}
function pidVerifierErrorCategory(error) {
    const code = typeof (error === null || error === void 0 ? void 0 : error.code) === 'string' ?
        error.code : '';
    if (code === 'unauthenticated')
        return 'authentication';
    if (code === 'permission-denied')
        return 'authorization';
    if (code === 'failed-precondition')
        return 'configuration';
    if (code === 'unavailable' || code === 'deadline-exceeded')
        return 'transport';
    return 'unexpected';
}
//# sourceMappingURL=pid_verifier_logging.js.map