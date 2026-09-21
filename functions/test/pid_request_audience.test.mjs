import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { generateKeyPairSync, randomUUID, sign, verify } from 'node:crypto';
import { createRequire } from 'node:module';
import { pathToFileURL, URL } from 'node:url';
import test from 'node:test';

// Resolve the exact copy used by Credo, including if npm nests dependencies.
const credoRequire = createRequire(import.meta.resolve('@credo-ts/openid4vc'));
const { createOpenid4vpAuthorizationRequest } = await import(
  pathToFileURL(credoRequire.resolve('@openid4vc/openid4vp')).href
);
const walletAudience = 'https://self-issued.me/v2';
const { privateKey, publicKey } = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
const publicJwk = publicKey.export({ format: 'jwk' });

async function createRequest(requestUri, additionalJwtPayload) {
  const payload = {
    client_id: 'x509_hash:test-verifier',
    response_type: 'vp_token',
    response_mode: 'direct_post.jwt',
    response_uri: 'https://verifier.example/oid4vp/authorize',
    nonce: randomUUID(),
    state: randomUUID(),
    dcql_query: {
      credentials: [{
        id: 'pid-sd-jwt', format: 'dc+sd-jwt',
        meta: { vct_values: ['urn:eudi:pid:de:1'] },
        claims: [{ path: ['given_name'] }],
      }],
    },
    client_metadata: {
      jwks: { keys: [{ ...publicJwk, kid: 'response-key', use: 'enc', alg: 'ECDH-ES' }] },
      vp_formats_supported: {
        'dc+sd-jwt': { 'sd-jwt_alg_values': ['ES256'], 'kb-jwt_alg_values': ['ES256'] },
      },
      encrypted_response_enc_values_supported: ['A128GCM'],
    },
  };
  const result = await createOpenid4vpAuthorizationRequest({
    authorizationRequestPayload: payload,
    jar: {
      // The injected signing callback uses an ephemeral test key. This tests
      // JAR construction/signing, not RP certificate-chain validation.
      jwtSigner: { method: 'jwk', publicJwk, alg: 'ES256' },
      requestUri, expiresInSeconds: 300,
      ...(additionalJwtPayload ? { additionalJwtPayload } : {}),
    },
    callbacks: {
      signJwt: (_signer, jwt) => {
        const input = [jwt.header, jwt.payload]
          .map((part) => Buffer.from(JSON.stringify(part)).toString('base64url')).join('.');
        const signature = sign('sha256', Buffer.from(input), {
          key: privateKey, dsaEncoding: 'ieee-p1363',
        });
        return { jwt: `${input}.${signature.toString('base64url')}`, signerJwk: publicJwk };
      },
      encryptJwe: () => { throw new Error('Request encryption is not used in this flow'); },
    },
  });
  const compact = result.jar.authorizationRequestJwt;
  const [header, body, signature] = compact.split('.');
  assert.ok(verify('sha256', Buffer.from(`${header}.${body}`), {
    key: publicKey, dsaEncoding: 'ieee-p1363',
  }, Buffer.from(signature, 'base64url')), 'audience must be inside a valid signed JWT');
  const claims = JSON.parse(Buffer.from(body, 'base64url'));
  for (const [key, value] of Object.entries(payload)) {
    assert.deepEqual(claims[key], value, `${key} must be preserved`);
  }
  assert.equal(claims.exp - claims.iat, 300);
  assert.equal(new URL(result.authorizationRequest).searchParams.get('request_uri'), requestUri);
  return claims;
}

test('signed PID requests target the static wallet audience, independently of request URI', async () => {
  for (const requestUri of ['https://verifier.example/request/one', 'https://other.example/request/two']) {
    const claims = await createRequest(requestUri);
    assert.equal(claims.aud, walletAudience);
    assert.notEqual(claims.aud, requestUri);
  }
});

test('an explicit wallet audience is preserved for other discovery flows', async () => {
  const claims = await createRequest('https://verifier.example/request/three', {
    aud: 'https://wallet.example',
  });
  assert.equal(claims.aud, 'https://wallet.example');
});

test('Credo signs and persists the correct audience through its X.509/Askar path', async () => {
  const [core, node, askarModule, openid, native] = await Promise.all([
    import('@credo-ts/core'), import('@credo-ts/node'), import('@credo-ts/askar'),
    import('@credo-ts/openid4vc'), import('@openwallet-foundation/askar-nodejs'),
  ]);
  const agent = new core.Agent({
    config: { logger: new core.ConsoleLogger(core.LogLevel.Off) },
    dependencies: node.agentDependencies,
    modules: {
      x509: new core.X509Module(),
      askar: new askarModule.AskarModule({
        askar: native.askar,
        store: {
          id: `audience-test-${randomUUID()}`, key: randomUUID(),
          database: { type: 'sqlite', config: { inMemory: true } },
        },
      }),
      openid4vc: new openid.OpenId4VcModule({
        verifier: { baseUrl: 'https://verifier.example/oid4vp' },
      }),
    },
  });
  try {
    await agent.initialize();
    const imported = await agent.kms.importKey({ privateJwk: privateKey.export({ format: 'jwk' }) });
    const authorityKey = core.Kms.PublicJwk.fromPublicJwk(imported.publicJwk);
    authorityKey.keyId = imported.keyId;
    const certificate = await agent.x509.createCertificate({ authorityKey, issuer: 'CN=Audience Test' });
    certificate.keyId = imported.keyId;
    const verifier = await agent.openid4vc.verifier.createVerifier({ verifierId: 'audience-test' });
    const { verificationSession } = await agent.openid4vc.verifier.createAuthorizationRequest({
      requestSigner: { method: 'x5c', x5c: [certificate], clientIdPrefix: 'x509_hash' },
      verifierId: verifier.verifierId,
      version: 'v1', responseMode: 'direct_post.jwt', expirationInSeconds: 300,
      dcql: { query: { credentials: [{
        id: 'pid-sd-jwt', format: 'dc+sd-jwt',
        meta: { vct_values: ['urn:eudi:pid:de:1'] },
        claims: [{ path: ['given_name'] }],
      }] } },
    });
    const persisted = await agent.openid4vc.verifier.getVerificationSessionById(verificationSession.id);
    assert.equal(persisted.authorizationRequestJwt, verificationSession.authorizationRequestJwt);
    const [header, body, signature] = persisted.authorizationRequestJwt.split('.');
    const protectedHeader = JSON.parse(Buffer.from(header, 'base64url'));
    assert.equal(protectedHeader.typ, 'oauth-authz-req+jwt');
    assert.equal(protectedHeader.x5c.length, 1);
    assert.ok(verify('sha256', Buffer.from(`${header}.${body}`), {
      key: publicKey, dsaEncoding: 'ieee-p1363',
    }, Buffer.from(signature, 'base64url')));
    const claims = JSON.parse(Buffer.from(body, 'base64url'));
    assert.equal(claims.aud, walletAudience);
    assert.match(claims.client_id, /^x509_hash:/);
    assert.equal(claims.response_mode, 'direct_post.jwt');
    assert.equal(claims.exp - claims.iat, 300);
    assert.ok(claims.nonce && claims.state);
  } finally {
    await agent.shutdown();
  }
});
