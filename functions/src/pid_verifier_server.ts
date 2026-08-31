import express from 'express';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { timingSafeEqual } from 'node:crypto';
import {
  ensurePidVerifierAgent,
  pidVerifierApp,
  shutdownPidVerifierAgent,
} from './pid_verification.js';
import { readRuntimeSecret } from './pid_verifier_runtime_config.js';
import {
  logPidVerifierEvent,
  pidVerifierErrorCategory,
} from './pid_verifier_logging.js';

if (getApps().length === 0) {
  initializeApp({
    credential: applicationDefault(),
    projectId: process.env.GCLOUD_PROJECT?.trim() || 'stimmapp-dev',
  });
}

function isValidProxySecret(value: string | undefined, expected: string) {
  if (!value) return false;
  const actualBuffer = Buffer.from(value);
  const expectedBuffer = Buffer.from(expected);
  return actualBuffer.length === expectedBuffer.length &&
    timingSafeEqual(actualBuffer, expectedBuffer);
}

async function startServer() {
  const portValue = Number.parseInt(process.env.PORT ?? '8080', 10);
  if (!Number.isInteger(portValue) || portValue < 1 || portValue > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535.');
  }

  const proxySecret = readRuntimeSecret({
    environmentName: 'PID_VERIFIER_PROXY_SHARED_SECRET',
  });
  await ensurePidVerifierAgent();

  const serverApp = express();
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
    if (!isValidProxySecret(
      request.header('x-stimmapp-verifier-proxy'),
      proxySecret,
    )) {
      response.status(403).json({ error: 'Forbidden.' });
      return;
    }
    next();
  });
  serverApp.use(pidVerifierApp);

  const server = serverApp.listen(portValue, '0.0.0.0', () => {
    logPidVerifierEvent({
      event: 'verifier_started', outcome: 'success', status: 200,
      validationOutcome: 'not_applicable', protocolStage: 'initialization',
    });
  });

  let shuttingDown = false;
  const shutdown = () => {
    if (shuttingDown) return;
    shuttingDown = true;
    server.close(async (error) => {
      if (error) process.exitCode = 1;
      try {
        await shutdownPidVerifierAgent();
      } catch {
        process.exitCode = 1;
      }
    });
  };
  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);
}

startServer().catch((error: unknown) => {
  logPidVerifierEvent({
    event: 'verifier_start_failed', outcome: 'failure', status: 500,
    errorCategory: pidVerifierErrorCategory(error), errorCode: 'verifier_start_failed',
    protocolStage: 'initialization',
  });
  process.exitCode = 1;
});
