import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { env } from 'node:process';
import test from 'node:test';
import { Store, StoreKeyMethod, KdfMethod } from '@openwallet-foundation/askar-nodejs';
import { diagnosePidRequest, summarizePidSession } from '../lib/pid_verifier_diagnose.js';

test('diagnostic summarizes known errors without exposing stored protocol data', () => {
  assert.deepEqual(summarizePidSession({
    state: 'Error',
    errorMessage: 'pid-sd-jwt: The status list certificate chain could not be validated against the trusted status certificates. secret-token',
    authorizationResponsePayload: { given_name: 'private' },
  }), { state: 'Error', failureCode: 'status_list_trust_failed' });
  assert.deepEqual(summarizePidSession({ state: 'private', errorMessage: 'private' }), {
    state: 'unknown', failureCode: 'unclassified_verification_failure',
  });
});

test('diagnostic identifies the observed issuer-chain rejection inside the OpenID4VP wrapper', () => {
  assert.deepEqual(summarizePidSession({
    state: 'Error',
    errorMessage: 'One or more presentations failed verification.\n' +
      '\t- pid-sd-jwt[0]: Error occurred during verification of presentation. ' +
      'No trusted certificate was found while validating the X.509 chain, private-token',
  }), { state: 'Error', failureCode: 'issuer_chain_untrusted' });
  // The SDK wraps status-chain failures separately. Preserve the distinction.
  assert.deepEqual(summarizePidSession({
    state: 'Error',
    errorMessage: 'The status list certificate chain could not be validated against the trusted status certificates.',
  }), { state: 'Error', failureCode: 'status_list_trust_failed' });
});

test('diagnostic reads an existing native Askar request without changing its record', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'pid-diagnose-'));
  const path = join(directory, 'store.sqlite');
  const key = randomUUID();
  const names = ['PID_ASKAR_SQLITE_PATH', 'PID_ASKAR_STORE_KEY', 'PID_ASKAR_STORE_KEY_FILE', 'PID_ASKAR_POSTGRES_HOST'];
  const previous = names.map((name) => env[name]);
  const store = await Store.provision({
    uri: `sqlite://${path}`, passKey: key,
    keyMethod: new StoreKeyMethod(KdfMethod.Argon2IMod), recreate: false,
  });
  try {
    delete env.PID_ASKAR_POSTGRES_HOST;
    delete env.PID_ASKAR_STORE_KEY_FILE;
    env.PID_ASKAR_SQLITE_PATH = path;
    env.PID_ASKAR_STORE_KEY = key;
    const requestId = randomUUID();
    const session = await store.session().open();
    try {
      const item = {
        category: 'OpenId4VcVerificationSessionRecord', name: randomUUID(),
        tags: { authorizationRequestId: requestId },
        value: { state: 'Error', errorMessage: 'The key binding JWT does not contain the expected audience', authorizationRequestJwt: 'private' },
      };
      await session.insert(item);
      const before = await session.fetch({ category: item.category, name: item.name, isJson: true });
      assert.deepEqual(await diagnosePidRequest(requestId), {
        result: 'found', state: 'Error', failureCode: 'holder_audience_mismatch',
      });
      assert.deepEqual(await session.fetch({ category: item.category, name: item.name, isJson: true }), before);
      assert.deepEqual(await diagnosePidRequest(randomUUID()), { result: 'request_not_found' });
      await assert.rejects(diagnosePidRequest('invalid'), /invalid_request_id/);
    } finally {
      await session.close();
    }
  } finally {
    await store.close();
    names.forEach((name, i) => {
      if (previous[i] === undefined) delete env[name];
      else env[name] = previous[i];
    });
    await rm(directory, { recursive: true, force: true });
  }
});
