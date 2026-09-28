import { AsyncLocalStorage } from 'node:async_hooks';
import { createPublicKey, X509Certificate } from 'node:crypto';

export const PID_PREPROD_ISSUER = 'https://preprod.pid-provider.bundesdruckerei.de';

// This is an additional binding, never a replacement for signed-list X.509
// trust. Do not follow arbitrary credential URLs or metadata redirects.
export function createPidIssuerKeyResolver(fetchMetadata: typeof fetch = fetch) {
  let cached: { keys: string[]; until: number } | undefined;
  let pending: Promise<string[]> | undefined;
  return async (issuer: string, certificate: string): Promise<boolean> => {
    if (issuer !== PID_PREPROD_ISSUER) return false;
    const key = new X509Certificate(Buffer.from(certificate, 'base64')).publicKey
      .export({ type: 'spki', format: 'der' }).toString('base64');
    if (!cached || cached.until <= Date.now()) {
      pending ??= (async () => {
        const response = await fetchMetadata(`${PID_PREPROD_ISSUER}/.well-known/jwt-vc-issuer`, {
          redirect: 'error', signal: AbortSignal.timeout(10000),
        });
        if (!response.ok) throw new Error('PID issuer metadata unavailable.');
        const metadata = await response.json() as any;
        if (metadata.issuer !== PID_PREPROD_ISSUER || !Array.isArray(metadata.jwks?.keys)) {
          throw new Error('PID issuer metadata invalid.');
        }
        const keys = metadata.jwks.keys.filter((jwk: any) =>
          jwk.kty === 'EC' && jwk.crv === 'P-256' &&
          (!jwk.use || jwk.use === 'sig') && (!jwk.alg || jwk.alg === 'ES256'))
          .map((jwk: any) => createPublicKey({ key: jwk, format: 'jwk' })
            .export({ type: 'spki', format: 'der' }).toString('base64'));
        cached = { keys, until: Date.now() + 5 * 60 * 1000 };
        return keys;
      })().finally(() => { pending = undefined; });
      await pending;
    }
    return cached!.keys.includes(key);
  };
}

// Credo 0.7.1 has no public issuer-name-policy hook. Keep this compatibility
// adapter on this agent's service instance (not the SDK prototype), guarded by
// version and method checks. Remove it when upstream exposes an equivalent hook.
// AsyncLocalStorage confines the additional binding to its own verify call;
// signing, other issuers and concurrent verifications retain the SDK policy.
export async function createPidSdJwtVcModule(
  resolveIssuerKey = createPidIssuerKeyResolver(),
) {
  const { SdJwtVcModule, SdJwtVcService } = await import('@credo-ts/core');
  if (require('@credo-ts/core/package.json').version !== '0.7.1') {
    throw new Error('Review PID issuer binding adapter for this Credo version.');
  }
  const binding = new AsyncLocalStorage<{ issuer: string; certificate: string } | undefined>();
  const installed = new WeakSet<object>();
  return new class extends SdJwtVcModule {
    async onInitializeContext(context: Parameters<InstanceType<typeof SdJwtVcService>['verify']>[0]) {
      const service = context.resolve(SdJwtVcService);
      if (installed.has(service)) return;
      installed.add(service);
      // Explicit boundary to the pinned SDK's private synchronous name check.
      const internal = service as any;
      if (typeof internal.assertValidX5cJwtIssuer !== 'function') {
        throw new Error('PID issuer binding adapter is incompatible with Credo.');
      }
      const originalNameCheck = internal.assertValidX5cJwtIssuer.bind(service);
      internal.assertValidX5cJwtIssuer = (context: unknown, issuer: string, leaf: any) => {
        const verifiedBinding = binding.getStore();
        if (verifiedBinding?.issuer === issuer && verifiedBinding.certificate === leaf.toString('base64')) return;
        return originalNameCheck(context, issuer, leaf);
      };
      const originalVerify = service.verify.bind(service);
      service.verify = async (context, options) => {
        // No mutation of JWTs, decoded claims, certificates, or verification
        // options. Credo still checks chain trust, signatures, status and KB-JWT.
        let allowed: { issuer: string; certificate: string } | undefined;
        try {
          const [headerPart, payloadPart] = options.compactSdJwtVc.split('.');
          const header = JSON.parse(Buffer.from(headerPart, 'base64url').toString());
          const payload = JSON.parse(Buffer.from(payloadPart, 'base64url').toString());
          if (header.typ === 'dc+sd-jwt' && payload.vct === 'urn:eudi:pid:de:1' &&
              payload.iss === PID_PREPROD_ISSUER && Array.isArray(header.x5c) && header.x5c.length) {
            const leaf = new X509Certificate(Buffer.from(header.x5c[0], 'base64'));
            // A present but mismatching SAN must still fail the ordinary check.
            if (!leaf.subjectAltName && await resolveIssuerKey(payload.iss, header.x5c[0])) {
              allowed = { issuer: payload.iss, certificate: leaf.raw.toString('base64') };
            }
          }
        } catch {
          // Fail closed through the original name check on malformed input or
          // metadata outage; never turn an unverified issuer into a trusted one.
        }
        return binding.run(allowed, () => originalVerify(context, options));
      };
    }
  }();
}
