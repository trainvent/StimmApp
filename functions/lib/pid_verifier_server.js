"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const app_1 = require("firebase-admin/app");
const node_crypto_1 = require("node:crypto");
const pid_verification_js_1 = require("./pid_verification.js");
const pid_verifier_runtime_config_js_1 = require("./pid_verifier_runtime_config.js");
const pid_verifier_logging_js_1 = require("./pid_verifier_logging.js");
if ((0, app_1.getApps)().length === 0) {
    (0, app_1.initializeApp)({
        credential: (0, app_1.applicationDefault)(),
        projectId: ((_a = process.env.GCLOUD_PROJECT) === null || _a === void 0 ? void 0 : _a.trim()) || 'stimmapp-dev',
    });
}
function isValidProxySecret(value, expected) {
    if (!value)
        return false;
    const actualBuffer = Buffer.from(value);
    const expectedBuffer = Buffer.from(expected);
    return actualBuffer.length === expectedBuffer.length &&
        (0, node_crypto_1.timingSafeEqual)(actualBuffer, expectedBuffer);
}
async function startServer() {
    var _a;
    const portValue = Number.parseInt((_a = process.env.PORT) !== null && _a !== void 0 ? _a : '8080', 10);
    if (!Number.isInteger(portValue) || portValue < 1 || portValue > 65535) {
        throw new Error('PORT must be an integer between 1 and 65535.');
    }
    const proxySecret = (0, pid_verifier_runtime_config_js_1.readRuntimeSecret)({
        environmentName: 'PID_VERIFIER_PROXY_SHARED_SECRET',
    });
    await (0, pid_verification_js_1.ensurePidVerifierAgent)();
    const serverApp = (0, express_1.default)();
    serverApp.disable('x-powered-by');
    serverApp.use((_request, response, next) => {
        // Lets smoke tests prove that a response traversed the standalone origin
        // rather than Firebase's temporary embedded-verifier fallback.
        response.setHeader('x-stimmapp-verifier-origin', 'server');
        next();
    });
    serverApp.get('/healthz', (_request, response) => {
        response.status(200).json({ status: 'ok' });
    });
    serverApp.use((request, response, next) => {
        if (!isValidProxySecret(request.header('x-stimmapp-verifier-proxy'), proxySecret)) {
            response.status(403).json({ error: 'Forbidden.' });
            return;
        }
        next();
    });
    serverApp.use(pid_verification_js_1.pidVerifierApp);
    const server = serverApp.listen(portValue, '0.0.0.0', () => {
        (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
            event: 'verifier_started', outcome: 'success', status: 200,
            validationOutcome: 'not_applicable', protocolStage: 'initialization',
        });
    });
    let shuttingDown = false;
    const shutdown = () => {
        if (shuttingDown)
            return;
        shuttingDown = true;
        server.close(async (error) => {
            if (error)
                process.exitCode = 1;
            try {
                await (0, pid_verification_js_1.shutdownPidVerifierAgent)();
            }
            catch (_a) {
                process.exitCode = 1;
            }
        });
    };
    process.once('SIGINT', shutdown);
    process.once('SIGTERM', shutdown);
}
startServer().catch((error) => {
    (0, pid_verifier_logging_js_1.logPidVerifierEvent)({
        event: 'verifier_start_failed', outcome: 'failure', status: 500,
        errorCategory: (0, pid_verifier_logging_js_1.pidVerifierErrorCategory)(error), errorCode: 'verifier_start_failed',
        protocolStage: 'initialization',
    });
    process.exitCode = 1;
});
//# sourceMappingURL=pid_verifier_server.js.map