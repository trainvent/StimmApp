// Askar stores the verifier's keys, but does not implement ES512. The German
// sandbox PID CA uses P-521/SHA-512 for its certificate signatures.
export async function createPidKeyManagementModule() {
  const [{ Kms }, { NodeKeyManagementService, NodeInMemoryKeyManagementStorage }, { AskarKeyManagementService }] = await Promise.all([
    import('@credo-ts/core'), import('@credo-ts/node'), import('@credo-ts/askar'),
  ]);
  class CertificateVerificationBackend extends NodeKeyManagementService {
    isOperationSupported(...args: Parameters<InstanceType<typeof NodeKeyManagementService>['isOperationSupported']>) {
      const operation = args[1];
      return operation.operation === 'verify' && operation.algorithm === 'ES512' &&
        super.isOperationSupported(...args);
    }
  }
  return new Kms.KeyManagementModule({
    defaultBackend: 'askar',
    // Public-key verification needs no stored keys. Restrict this backend to
    // ES512 verification; all private keys remain in the persistent Askar store.
    backends: [new AskarKeyManagementService(), new CertificateVerificationBackend(new NodeInMemoryKeyManagementStorage())],
  });
}
