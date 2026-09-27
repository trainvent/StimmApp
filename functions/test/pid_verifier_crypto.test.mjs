import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { randomUUID, webcrypto, X509Certificate as NativeCertificate } from 'node:crypto';
import { createRequire } from 'node:module';
import test from 'node:test';
import { Agent, ConsoleLogger, LogLevel, X509Module, X509Service, Kms } from '@credo-ts/core';
import { agentDependencies } from '@credo-ts/node';
import { AskarModule } from '@credo-ts/askar';
import { askar } from '@openwallet-foundation/askar-nodejs';
import { createPidKeyManagementModule } from '../lib/pid_verifier_crypto.js';

const require = createRequire(import.meta.resolve('@credo-ts/core'));
const { X509CertificateGenerator, BasicConstraintsExtension, KeyUsagesExtension, KeyUsageFlags } = require('@peculiar/x509');

async function agentWithCrypto(fixed) {
  return new Agent({
    config: { logger: new ConsoleLogger(LogLevel.Off) },
    dependencies: agentDependencies,
    modules: {
      ...(fixed ? { kms: await createPidKeyManagementModule() } : {}),
      x509: new X509Module(),
      askar: new AskarModule({
        askar, enableKms: !fixed,
        store: { id: randomUUID(), key: randomUUID(), database: { type: 'sqlite', config: { inMemory: true } } },
      }),
    },
  });
}

async function certificates() {
  const keys = await webcrypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-521' }, true, ['sign', 'verify']);
  const leafKeys = await webcrypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
  const now = Date.now();
  const common = {
    notBefore: new Date(now - 60000), notAfter: new Date(now + 3600000),
    signingAlgorithm: { name: 'ECDSA', hash: 'SHA-512' },
  };
  const ca = await X509CertificateGenerator.createSelfSigned({
    ...common, serialNumber: '01', name: 'CN=Synthetic P521 CA', keys,
    extensions: [new BasicConstraintsExtension(true, 0, true), new KeyUsagesExtension(KeyUsageFlags.keyCertSign, true)],
  }, webcrypto);
  const leaf = await X509CertificateGenerator.create({
    ...common, serialNumber: '02', subject: 'CN=Synthetic PID', issuer: ca.subject,
    publicKey: leafKeys.publicKey, signingKey: keys.privateKey,
    extensions: [new BasicConstraintsExtension(false), new KeyUsagesExtension(KeyUsageFlags.digitalSignature, true)],
  }, webcrypto);
  return { ca: ca.toString('base64'), leaf: leaf.toString('base64') };
}

test('P-521 issuer chains fail with Askar alone and pass with the verification backend', async () => {
  const { ca, leaf } = await certificates();
  assert.ok(new NativeCertificate(Buffer.from(leaf, 'base64')).verify(new NativeCertificate(Buffer.from(ca, 'base64')).publicKey));
  const old = await agentWithCrypto(false);
  const fixed = await agentWithCrypto(true);
  const options = { certificateChain: [leaf], trustedCertificates: [ca] };
  await assert.rejects(X509Service.validateCertificateChain(old.context, options), /No trusted certificate/);
  assert.equal((await X509Service.validateCertificateChain(fixed.context, options)).length, 2);

  const other = await certificates();
  await assert.rejects(X509Service.validateCertificateChain(fixed.context, { ...options, trustedCertificates: [other.ca] }));
  const corrupted = Buffer.from(leaf, 'base64');
  corrupted[corrupted.length - 1] ^= 1;
  await assert.rejects(X509Service.validateCertificateChain(fixed.context, { ...options, certificateChain: [corrupted.toString('base64')] }));
  await assert.rejects(X509Service.validateCertificateChain(fixed.context, { ...options, verificationDate: new Date(Date.now() + 7200000) }));
});

test('Askar remains the default for private keys; Node backend only verifies ES512', async () => {
  const agent = await agentWithCrypto(true);
  const config = agent.context.resolve(Kms.KeyManagementModuleConfig);
  assert.equal(config.defaultBackend.backend, 'askar');
  const node = config.backends.find(b => b.backend === 'node');
  assert.equal(node.isOperationSupported(agent.context, { operation: 'verify', algorithm: 'ES512' }), true);
  assert.equal(node.isOperationSupported(agent.context, { operation: 'sign', algorithm: 'ES512' }), false);
  assert.equal(node.isOperationSupported(agent.context, { operation: 'createKey', type: { kty: 'EC', crv: 'P-521' } }), false);
  try {
    await agent.initialize();
    const key = await agent.kms.createKey({ type: { kty: 'EC', crv: 'P-256' } });
    const data = Buffer.from('synthetic verifier signing check');
    const { signature } = await agent.kms.sign({ keyId: key.keyId, algorithm: 'ES256', data });
    assert.equal((await agent.kms.verify({ key: { publicJwk: key.publicJwk }, algorithm: 'ES256', data, signature })).verified, true);
  } finally {
    await agent.shutdown();
  }
});
