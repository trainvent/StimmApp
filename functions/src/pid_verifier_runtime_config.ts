import { readFileSync } from 'node:fs';

type RuntimeSecretOptions = {
  environmentName: string;
  fileEnvironmentName?: string;
  required?: boolean;
};

/**
 * Reads a runtime secret from a mounted file, falling back to an environment
 * variable for Firebase Secret Manager and local development.
 */
export function readRuntimeSecret({
  environmentName,
  fileEnvironmentName = `${environmentName}_FILE`,
  required = true,
}: RuntimeSecretOptions) {
  const filePath = process.env[fileEnvironmentName]?.trim();
  const value = filePath ? readFileSync(filePath, 'utf8').trim() :
    process.env[environmentName]?.trim();

  if (required && !value) {
    throw new Error(
      `Missing ${environmentName}; set ${environmentName} or ${fileEnvironmentName}.`,
    );
  }

  return value ?? '';
}

export type PidAskarStoreConfig = {
  id: string;
  key: string;
  database: {
    type: 'sqlite';
    config: { path: string };
  } | {
    type: 'postgres';
    config: {
      host: string;
      minConnections: number;
      maxConnections: number;
    };
    credentials: {
      account: string;
      password: string;
    };
  };
};

export function getPidAskarStoreConfig(): PidAskarStoreConfig {
  const postgresHost = process.env.PID_ASKAR_POSTGRES_HOST?.trim();
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
          path: process.env.PID_ASKAR_SQLITE_PATH?.trim() ||
            '/tmp/stimmapp-pid-verifier/askar.sqlite',
        },
      },
    };
  }

  const account = process.env.PID_ASKAR_POSTGRES_ACCOUNT?.trim();
  const database = process.env.PID_ASKAR_POSTGRES_DATABASE?.trim();
  if (!account || !database) {
    throw new Error(
      'PID_ASKAR_POSTGRES_ACCOUNT and PID_ASKAR_POSTGRES_DATABASE are required ' +
      'when PID_ASKAR_POSTGRES_HOST is configured.',
    );
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
