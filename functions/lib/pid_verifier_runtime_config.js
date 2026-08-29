"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.readRuntimeSecret = readRuntimeSecret;
exports.getPidAskarStoreConfig = getPidAskarStoreConfig;
const node_fs_1 = require("node:fs");
/**
 * Reads a runtime secret from a mounted file, falling back to an environment
 * variable for Firebase Secret Manager and local development.
 */
function readRuntimeSecret({ environmentName, fileEnvironmentName = `${environmentName}_FILE`, required = true, }) {
    var _a, _b;
    const filePath = (_a = process.env[fileEnvironmentName]) === null || _a === void 0 ? void 0 : _a.trim();
    const value = filePath ? (0, node_fs_1.readFileSync)(filePath, 'utf8').trim() :
        (_b = process.env[environmentName]) === null || _b === void 0 ? void 0 : _b.trim();
    if (required && !value) {
        throw new Error(`Missing ${environmentName}; set ${environmentName} or ${fileEnvironmentName}.`);
    }
    return value !== null && value !== void 0 ? value : '';
}
function getPidAskarStoreConfig() {
    var _a, _b, _c, _d;
    const postgresHost = (_a = process.env.PID_ASKAR_POSTGRES_HOST) === null || _a === void 0 ? void 0 : _a.trim();
    if (!postgresHost) {
        return {
            id: 'stimmapp-pid-verifier-store',
            key: readRuntimeSecret({
                environmentName: 'PID_ASKAR_STORE_KEY',
                required: false,
            }) || 'stimmapp-pid-verifier-key',
            database: {
                type: 'sqlite',
                config: {
                    path: ((_b = process.env.PID_ASKAR_SQLITE_PATH) === null || _b === void 0 ? void 0 : _b.trim()) ||
                        '/tmp/stimmapp-pid-verifier/askar.sqlite',
                },
            },
        };
    }
    const account = (_c = process.env.PID_ASKAR_POSTGRES_ACCOUNT) === null || _c === void 0 ? void 0 : _c.trim();
    const database = (_d = process.env.PID_ASKAR_POSTGRES_DATABASE) === null || _d === void 0 ? void 0 : _d.trim();
    if (!account || !database) {
        throw new Error('PID_ASKAR_POSTGRES_ACCOUNT and PID_ASKAR_POSTGRES_DATABASE are required ' +
            'when PID_ASKAR_POSTGRES_HOST is configured.');
    }
    return {
        // Credo uses the store id as the PostgreSQL database name.
        id: database,
        key: readRuntimeSecret({ environmentName: 'PID_ASKAR_STORE_KEY' }),
        database: {
            type: 'postgres',
            config: {
                host: postgresHost,
                minConnections: 1,
                maxConnections: 4,
            },
            credentials: {
                account,
                password: readRuntimeSecret({
                    environmentName: 'PID_ASKAR_POSTGRES_PASSWORD',
                    fileEnvironmentName: 'PID_ASKAR_POSTGRES_PASSWORD_FILE',
                }),
            },
        },
    };
}
//# sourceMappingURL=pid_verifier_runtime_config.js.map