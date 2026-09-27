import { verify as verifySignature } from 'node:crypto';

// Parse only after the signed list and its validity window have been verified.
export function parsePidTrustedIssuers(payload: Record<string, any>): PidTrustListCache['issuers'] {
  const entities = payload.LoTE?.TrustedEntitiesList;
  const issuers = Array.isArray(entities) ? entities.flatMap((entity: any) => {
    const services = entity?.TrustedEntityServices;
    if (!Array.isArray(services)) return [];
    const certificates = (type: string): string[] => [...new Set<string>(services.flatMap((service: any) => {
      const info = service?.ServiceInformation;
      if (info?.ServiceTypeIdentifier !== `http://uri.etsi.org/19602/SvcType/PID/${type}`) return [];
      const values = info?.ServiceDigitalIdentity?.X509Certificates;
      return Array.isArray(values) ? values.map((cert: any) => cert?.val)
        .filter((cert: unknown): cert is string => typeof cert === 'string' && cert.length > 0) : [];
    }))];
    const issuance = certificates('Issuance');
    const status = certificates('Revocation');
    return issuance.length ? [{ method: 'x509' as const, issuance, ...(status.length ? { status } : {}) }] : [];
  }) : [];
  if (!issuers.length) throw new Error('The official EUDI sandbox PID trust list contains no PID issuance certificates.');
  return issuers;
}

const PID_SANDBOX_TRUST_LIST_BASE_URL =
  'https://bmi.usercontent.opencode.de/eudi-wallet/test-trust-lists';

type PidTrustListCache = {
  issuers: { method: 'x509'; issuance: string[]; status?: string[] }[];
  validUntil: number;
};

let pidTrustListCache: PidTrustListCache | undefined;
let pidTrustListPromise: Promise<PidTrustListCache> | undefined;

function decodeBase64UrlJson(value: string): Record<string, any> {
  return JSON.parse(Buffer.from(value, 'base64url').toString('utf8')) as Record<string, any>;
}

function pemCertificateBody(value: string) {
  return value
    .replace(/-----BEGIN CERTIFICATE-----/g, '')
    .replace(/-----END CERTIFICATE-----/g, '')
    .replace(/\s/g, '');
}

async function fetchPidSandboxTrustList(): Promise<PidTrustListCache> {
  const [trustListResponse, signingCertificateResponse] = await Promise.all([
    fetch(`${PID_SANDBOX_TRUST_LIST_BASE_URL}/pid-provider.jwt`),
    fetch(`${PID_SANDBOX_TRUST_LIST_BASE_URL}/certificate.pem`),
  ]);
  if (!trustListResponse.ok || !signingCertificateResponse.ok) {
    throw new Error('The official EUDI sandbox PID trust list could not be downloaded.');
  }

  const compactJwt = (await trustListResponse.text()).trim();
  const signingCertificate = (await signingCertificateResponse.text()).trim();
  const parts = compactJwt.split('.');
  if (parts.length !== 3) {
    throw new Error('The official EUDI sandbox PID trust list is not a compact JWT.');
  }

  const header = decodeBase64UrlJson(parts[0]);
  if (header.alg !== 'ES256' || header.typ !== 'trustlist+jwt' ||
      !Array.isArray(header.x5c) || header.x5c[0] !== pemCertificateBody(signingCertificate)) {
    throw new Error('The official EUDI sandbox PID trust-list signer is invalid.');
  }

  const signatureValid = verifySignature(
    'sha256',
    Buffer.from(`${parts[0]}.${parts[1]}`, 'ascii'),
    { key: signingCertificate, dsaEncoding: 'ieee-p1363' },
    Buffer.from(parts[2], 'base64url'),
  );
  if (!signatureValid) {
    throw new Error('The official EUDI sandbox PID trust-list signature is invalid.');
  }

  const payload = decodeBase64UrlJson(parts[1]);
  const listInformation = payload.LoTE?.ListAndSchemeInformation;
  const issueTime = Date.parse(listInformation?.ListIssueDateTime ?? '');
  const nextUpdate = Date.parse(listInformation?.NextUpdate ?? '');
  const now = Date.now();
  if (!Number.isFinite(issueTime) || !Number.isFinite(nextUpdate) ||
      issueTime > now + 5 * 60 * 1000 || nextUpdate <= now) {
    throw new Error('The official EUDI sandbox PID trust list is not currently valid.');
  }

  const issuers = parsePidTrustedIssuers(payload);

  return {
    issuers,
    // Refresh before the signed list expires, but avoid downloading it for
    // each verification handled by a warm Cloud Functions instance.
    validUntil: Math.min(nextUpdate - 5 * 60 * 1000, now + 60 * 60 * 1000),
  };
}

export async function getPidSandboxTrustedIssuers() {
  if (pidTrustListCache && pidTrustListCache.validUntil > Date.now()) {
    return pidTrustListCache.issuers;
  }
  if (!pidTrustListPromise) {
    pidTrustListPromise = fetchPidSandboxTrustList()
      .then((result) => (pidTrustListCache = result))
      .finally(() => {
        pidTrustListPromise = undefined;
      });
  }
  return (await pidTrustListPromise).issuers;
}

