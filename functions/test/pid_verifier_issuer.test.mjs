import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { createHash, createPrivateKey, randomUUID, sign, webcrypto } from 'node:crypto';
import { createRequire } from 'node:module';
import { deflateSync } from 'node:zlib';
import test from 'node:test';
import { Agent, ConsoleLogger, LogLevel, X509Module } from '@credo-ts/core';
import { agentDependencies } from '@credo-ts/node';
import { AskarModule } from '@credo-ts/askar';
import { askar } from '@openwallet-foundation/askar-nodejs';
import { createPidKeyManagementModule } from '../lib/pid_verifier_crypto.js';
import { createPidIssuerKeyResolver, createPidSdJwtVcModule, PID_PREPROD_ISSUER } from '../lib/pid_verifier_issuer.js';
import { parsePidTrustedIssuers } from '../lib/pid_verifier_trust.js';
const require = createRequire(import.meta.resolve('@credo-ts/core'));
const { X509CertificateGenerator, BasicConstraintsExtension, KeyUsagesExtension, KeyUsageFlags, SubjectAlternativeNameExtension } = require('@peculiar/x509');
const statusUri = 'https://status.example/list';
const keyBinding = { audience: 'https://verifier.example', nonce: 'synthetic-nonce' };

async function signer(name, san) {
  const caKeys = await webcrypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-521' }, true, ['sign', 'verify']);
  const keys = await webcrypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
  const common = { notBefore: new Date(Date.now() - 60000), notAfter: new Date(Date.now() + 3600000), signingAlgorithm: { name: 'ECDSA', hash: 'SHA-512' } };
  const ca = await X509CertificateGenerator.createSelfSigned({ ...common, serialNumber: '01', name: `CN=${name} CA`, keys: caKeys,
    extensions: [new BasicConstraintsExtension(true, 0, true), new KeyUsagesExtension(KeyUsageFlags.keyCertSign, true)] }, webcrypto);
  const leaf = await X509CertificateGenerator.create({ ...common, serialNumber: '02', subject: `CN=${name}`, issuer: ca.subject,
    publicKey: keys.publicKey, signingKey: caKeys.privateKey,
    extensions: [new BasicConstraintsExtension(false), new KeyUsagesExtension(KeyUsageFlags.digitalSignature, true),
      ...(san ? [new SubjectAlternativeNameExtension([{ type: 'dns', value: san }])] : [])] }, webcrypto);
  return { ca: ca.toString('base64'), leaf: leaf.toString('base64'),
    privateKey: createPrivateKey({ key: await webcrypto.subtle.exportKey('jwk', keys.privateKey), format: 'jwk' }),
    publicJwk: await webcrypto.subtle.exportKey('jwk', keys.publicKey) };
}
function jwt(header, payload, key) {
  const input = [header, payload].map(v => Buffer.from(JSON.stringify(v)).toString('base64url')).join('.');
  return `${input}.${sign('sha256', Buffer.from(input), { key, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
}
function metadataResolver(key, overrides = {}) {
  return createPidIssuerKeyResolver(async (url, options) => {
    assert.equal(url, `${PID_PREPROD_ISSUER}/.well-known/jwt-vc-issuer`);
    assert.equal(options.redirect, 'error');
    return { ok: true, json: async () => ({ issuer: PID_PREPROD_ISSUER, jwks: { keys: [key] }, ...overrides }) };
  });
}
function entity(issuance, status) {
  return { TrustedEntityServices: [['Issuance', issuance], ['Revocation', status]].map(([type, certificate]) => ({
    ServiceInformation: { ServiceTypeIdentifier: `http://uri.etsi.org/19602/SvcType/PID/${type}`,
      ServiceDigitalIdentity: { X509Certificates: [{ val: certificate }] } },
  })) };
}

test('issuer metadata binding fails closed and only fetches the fixed HTTPS issuer', async () => {
  const a = await signer('Metadata A');
  const b = await signer('Metadata B');
  const resolver = metadataResolver(a.publicJwk);
  assert.equal(await resolver(PID_PREPROD_ISSUER, a.leaf), true);
  assert.equal(await resolver(PID_PREPROD_ISSUER, b.leaf), false);
  assert.equal(await resolver('https://attacker.example', a.leaf), false);
  assert.equal(await resolver(`${PID_PREPROD_ISSUER}/unexpected`, a.leaf), false);
  await assert.rejects(metadataResolver(a.publicJwk, { issuer: 'https://attacker.example' })(PID_PREPROD_ISSUER, a.leaf));
  await assert.rejects(createPidIssuerKeyResolver(async () => { throw Error('offline'); })(PID_PREPROD_ISSUER, a.leaf));
});

test('PID verification binds issuer metadata, entity-specific status trust and holder proof', async () => {
  const issuer = await signer('Issuer');
  const statusSigner = await signer('Status');
  const foreign = await signer('Foreign');
  const mismatchingSan = await signer('Mismatching SAN', 'wrong.example');
  const trustedIssuers = parsePidTrustedIssuers({ LoTE: { TrustedEntitiesList: [
    entity(issuer.ca, statusSigner.ca), entity(foreign.ca, foreign.ca), entity(mismatchingSan.ca, statusSigner.ca),
  ] } });
  assert.deepEqual(trustedIssuers[0], { method: 'x509', issuance: [issuer.ca], status: [statusSigner.ca] });
  let activeStatusSigner = statusSigner;
  let revoked = false;
  let badStatusSignature = false;
  let metadataKey = issuer.publicJwk;
  let metadataOffline = false;
  const resolver = async (iss, cert) => {
    if (metadataOffline) throw Error('offline');
    return metadataResolver(metadataKey)(iss, cert);
  };
  const agent = new Agent({
    config: { logger: new ConsoleLogger(LogLevel.Off), getTrustedIssuersForVerification: async () => ({ trustedIssuers }) },
    dependencies: { ...agentDependencies, fetch: async (url) => {
      assert.equal(url, statusUri);
      const now = Math.floor(Date.now() / 1000);
      return { ok: true, text: async () => jwt({ alg: 'ES256', typ: 'statuslist+jwt', x5c: [activeStatusSigner.leaf] }, {
        sub: statusUri, iat: now, exp: now + 600, ttl: 600,
        status_list: { bits: 1, lst: deflateSync(Buffer.from([revoked ? 1 : 0])).toString('base64url') },
      }, badStatusSignature ? foreign.privateKey : activeStatusSigner.privateKey) };
    } },
    modules: {
      kms: await createPidKeyManagementModule(), x509: new X509Module(),
      askar: new AskarModule({ askar, enableKms: false, store: { id: randomUUID(), key: randomUUID(), database: { type: 'sqlite', config: { inMemory: true } } } }),
      sdJwtVc: await createPidSdJwtVcModule(resolver),
    },
  });
  const present = (options = {}) => {
    const signingIssuer = options.signer ?? issuer;
    const now = Math.floor(Date.now() / 1000);
    const compact = jwt({ alg: 'ES256', typ: 'dc+sd-jwt', x5c: [signingIssuer.leaf] }, {
      iss: options.iss ?? PID_PREPROD_ISSUER, vct: options.vct ?? 'urn:eudi:pid:de:1',
      iat: now, exp: now + 600, cnf: { jwk: foreign.publicJwk },
      status: { status_list: { idx: 0, uri: statusUri } }, given_name: 'SYNTHETIC',
    }, options.badSignature ? foreign.privateKey : signingIssuer.privateKey) + '~';
    return compact + jwt({ alg: 'ES256', typ: 'kb+jwt' }, {
      aud: keyBinding.audience, nonce: keyBinding.nonce, iat: now,
      sd_hash: createHash('sha256').update(compact).digest('base64url'),
    }, options.badHolderSignature ? issuer.privateKey : foreign.privateKey);
  };
  const verify = (token = present(), extra = {}) => agent.sdJwtVc.verify({ compactSdJwtVc: token, keyBinding, ...extra });
  try {
    await agent.initialize();
    assert.equal((await verify()).isValid, true);
    // The previous issuance-only trust pool cannot authorize the separate status signer.
    const legacy = await verify(present(), { trustedIssuers: undefined, trustedCertificates: [issuer.ca] });
    assert.equal(legacy.isValid, false);
    assert.match(legacy.error.message, /status list certificate chain/);
    activeStatusSigner = foreign;
    assert.equal((await verify()).isValid, false, 'another trusted entity cannot sign this issuer status');
    activeStatusSigner = statusSigner;
    badStatusSignature = true;
    assert.equal((await verify()).isValid, false);
    badStatusSignature = false;
    revoked = true;
    assert.equal((await verify()).isValid, false);
    revoked = false;
    assert.equal((await verify(present({ badSignature: true }))).isValid, false);
    assert.equal((await verify(present({ badHolderSignature: true }))).isValid, false);
    assert.equal((await verify(present(), { keyBinding: { ...keyBinding, nonce: 'wrong' } })).isValid, false);
    assert.equal((await verify(present(), { keyBinding: { ...keyBinding, audience: 'https://wrong.example' } })).isValid, false);
    assert.equal((await verify(present(), { trustedIssuers: [] })).isValid, false, 'metadata cannot replace chain trust');
    metadataKey = foreign.publicJwk;
    assert.equal((await verify()).isValid, false, 'metadata key mismatch must reject');
    metadataKey = issuer.publicJwk;
    metadataOffline = true;
    assert.equal((await verify()).isValid, false);
    metadataOffline = false;
    assert.equal((await verify(present({ iss: 'https://attacker.example' }))).isValid, false);
    assert.equal((await verify(present({ vct: 'urn:other:credential' }))).isValid, false);
    metadataKey = mismatchingSan.publicJwk;
    assert.equal((await verify(present({ signer: mismatchingSan }))).isValid, false, 'explicit SAN mismatch must reject');
    metadataKey = issuer.publicJwk;
    const results = await Promise.all([verify(), verify(present({ iss: 'https://attacker.example' })), verify()]);
    assert.deepEqual(results.map(r => r.isValid), [true, false, true], 'issuer binding must not leak between concurrent calls');
  } finally { await agent.shutdown(); }
});
