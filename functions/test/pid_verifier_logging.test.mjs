import assert from 'node:assert/strict';
import test from 'node:test';
import { logPidVerifierEvent } from '../lib/pid_verifier_logging.js';

/* global process */

test('PID verifier logs have a strict allowlisted JSON schema', () => {
  const previous = process.env.PID_VERIFIER_LOG_ENV;
  process.env.PID_VERIFIER_LOG_ENV = 'sandbox';
  const records = [];
  try {
    const record = logPidVerifierEvent({
      traceId: 'trace-safe', event: 'session_verified', outcome: 'success',
      status: 200, latencyMs: 12.4, validationOutcome: 'success',
      protocolStage: 'status_check', pidClaim: 'must-not-be-logged',
      rawError: { token: 'must-not-be-logged' },
    }, (value) => records.push(value));

    assert.deepEqual(records, [record]);
    assert.equal(record.traceId, 'trace-safe');
    assert.equal(record.latencyMs, 12);
    assert.equal(record.validationOutcome, 'success');
    assert.equal(typeof record.timestamp, 'string');
    assert.deepEqual(Object.keys(record).sort(), [
      'event', 'invocationMethod', 'latencyMs', 'outcome', 'protocolStage',
      'status', 'timestamp', 'traceId', 'validationOutcome',
    ]);
  } finally {
    if (previous === undefined) delete process.env.PID_VERIFIER_LOG_ENV;
    else process.env.PID_VERIFIER_LOG_ENV = previous;
  }
});

test('production omits sandbox-only diagnostics', () => {
  const previous = process.env.PID_VERIFIER_LOG_ENV;
  process.env.PID_VERIFIER_LOG_ENV = 'production';
  try {
    const record = logPidVerifierEvent({
      event: 'session_failed', outcome: 'failure', protocolStage: 'wallet_response',
      validationOutcome: 'failure', errorCategory: 'validation',
    }, () => {});
    assert.equal('protocolStage' in record, false);
    assert.equal(record.errorCategory, 'validation');
  } finally {
    if (previous === undefined) delete process.env.PID_VERIFIER_LOG_ENV;
    else process.env.PID_VERIFIER_LOG_ENV = previous;
  }
});
