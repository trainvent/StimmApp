# iOS PID claim comparison — 2026-09-22

## Follow-up: reissuance passes claim matching

The user deleted and recreated the wallet identity. The new screenshot and
`eudi-ios-wallet-logs 4.txt` show that all seven requested fields now match and
the wallet reaches consent and response submission. The prior missing-name
failure is resolved for this fresh credential. This supports a stored-credential
problem but does not retrospectively prove expiry or the precise exclusion guard.

The next failure is verifier-side: the first presentation POST receives HTTP 400
at 2026-09-22 08:24:43 UTC (10:24:43 CEST), followed by the wallet error at
08:24:44 UTC. Lines 5925–5935 report `invalid_request` with description
`One or more presentations failed verification.` The response includes
`x-stimmapp-verifier-origin: server`, locating the rejection at the standalone
verifier behind the Firebase proxy.

Correlation trace: `4f1088164cac2b1b79894a961838f74e`.
Later attempts at 08:25:11 and 08:26:09 UTC receive `Invalid session`; diagnose
the first verification failure before these retries. Use a fresh StimmApp
verification session for the next controlled attempt.

Server handoff: inspect the verifier container logs around 08:24:40–08:24:50 UTC
and the failed Credo verification-session record for the underlying validation
error. From the deployment's Compose directory, the initial read-only log check is:

```sh
docker compose logs --no-color --since '2026-09-22T08:24:35Z' --until '2026-09-22T08:24:55Z' verifier
```

Do not share raw presentation tokens, identity claims, or secrets. Return the
validation stage and sanitized error code/message only. Credo logging is disabled
in the repository configuration, so generic HTTP logs may be insufficient; a
targeted read-only inspection of the stored verification result may be needed.
The wallet export alone does not identify a signature, trust, nonce, disclosure,
or holder-binding root cause. No further certificate rotation is justified yet.

## Investigation result

The best-supported diagnosis is a wallet-side presentation eligibility/indexing
problem, rather than an incorrect `given_name` query. The exact on-device trigger
is **not yet proven**: the exported log contains neither the SD-JWT's expiry nor
the reason it was excluded. Expired or unparseable expiry metadata is the leading
candidate; parsing failure, missing key metadata, and unavailable credential data
remain alternatives.

Read-only device inspection reports `org.sprind.wallet.sandbox`, d-you version
0.3.1, build 78. The German public app source inspected is revision
`3dac5507ad19d5580f3ff3aae8bb6cf16494d784`. Its Package.resolved pins wallet-kit to
`01d673c8804be1254b1e29c9cc66cddc822af216`, storage to 0.22.0, and SD-JWT to 0.14.6.
The installed binary's exact dependency revisions cannot be verified from the
app-version listing alone, so source-to-binary correspondence remains a limit.

### Why the displayed first name was inconclusive

The user confirmed that the PID details show a first name. In the German app,
`DashboardInteractor.getPIDDocument()` explicitly selects `.mDocPid`.
The normal credential-details route uses that document. The separately stored
SD-JWT is what our request selects. Therefore that screen can show the correct
name while the SD-JWT is unavailable for presentation.

Source: [German app DashboardInteractor](https://github.com/german-national-wallet/de-eudi-wallet-ios/blob/3dac5507ad19d5580f3ff3aae8bb6cf16494d784/Modules/feature-dashboard/Sources/Interactor/DashboardInteractor.swift#L49).

### Concrete SDK defect found

In `EudiWallet.prepareServiceDataParameters()`:

1. Batched credentials whose model has `validUntil == nil` or a past expiry have
   their key-info entry removed before the individual credential is loaded.
2. `docData` is filtered against the remaining key-info entries.
3. `idsToDocTypes` is nevertheless constructed from **all** original documents.
   The empty-data guard also checks the original `idsToDocData`, not the filtered
   `docData`.
4. `makeCredentialMap` builds candidates from those unfiltered IDs.
5. An excluded credential has no reconstructed claim paths. `hasClaim` returns
   false, and resolution reports the first requested claim as missing.

Thus `Claim not found: given_name` does not establish that an otherwise usable
credential lacks a first name. The SDK can generate this error for an unavailable
credential containing that claim.

Sources: [eligibility filtering](https://github.com/german-national-wallet/de-eudi-lib-ios-wallet-kit/blob/01d673c8804be1254b1e29c9cc66cddc822af216/Sources/EudiWalletKit/EudiWallet.swift#L590),
[candidate construction](https://github.com/german-national-wallet/de-eudi-lib-ios-wallet-kit/blob/01d673c8804be1254b1e29c9cc66cddc822af216/Sources/EudiWalletKit/Services/Openid4VpUtils.swift#L84),
[claim lookup](https://github.com/german-national-wallet/de-eudi-lib-ios-wallet-kit/blob/01d673c8804be1254b1e29c9cc66cddc822af216/Sources/EudiWalletKit/Services/DcqlQueryable.swift#L59).

### Evidence and reproduction

The log shows ten credential keys stored for the failing SD-JWT on August 22.
The September 22 attempt logs `Load documents with status: issued`, but no
individual `Load document with status: issued` entry. Storage 0.22.0 logs individual
loads in `loadDocumentHelper`. This supports early exclusion of the batched
credential, but log completeness and installed-library correspondence prevent it
from proving which guard ran. Age alone does not establish expiry.

The [isolated Swift reproduction](diagnostics/eudi_wallet_candidate_repro.swift)
uses the pinned SDK's candidate-map and queryable implementations, with minimal
model stubs. It passed three assertions: a healthy claim matches, an excluded
credential remains a candidate with no claims, and restricting metadata to eligible
data removes that false candidate. This reproduces the indexing defect; it does
not reproduce issuance, expiry parsing, or the private credential on the phone.

### Next action and wallet fix

The practical recovery test is to renew/reissue the sandbox PID through the
wallet's supported flow, then start a fresh StimmApp session. No automatic wallet
reset, deletion, reissuance, or private-credential export was performed. Success
after renewal would support the stored-credential diagnosis, but would not alone
distinguish expiry from a storage/issuance defect.

For the wallet maintainers, the concrete fix is to build candidate metadata only
from eligible, successfully decoded credentials and check the filtered data for
emptiness. Preserve a structured exclusion reason (expired, missing expiry,
exhausted, missing key, decode failure) instead of converting all of these into
missing claims. Retain the existing expiry and key-eligibility checks. Add a full
SDK regression test with a batched expired credential and a healthy control.

No StimmApp query change or verifier deployment is justified by this evidence.
This report is prepared for handoff; it has not been posted to the wallet project.

## Observed failure

The September 22 attempt in `eudi-ios-wallet-logs 3.txt` fetches the authorization
request with HTTP 200 and proceeds through request processing to credential
matching. Line 2859 reports `Claim not found: given_name` for query `pid-sd-jwt`.
The earlier audience errors in this file belong to September 21 attempts.

The credential ID in the failure matches the credential stored on August 22 at
line 1076, with type `urn:eudi:pid:de:1`. A separate mDoc credential is stored at
line 1088. The log therefore identifies the expected SD-JWT PID type; the presence
of MdocSecurity log messages does not by itself mean we requested the wrong format.

## Repository query versus official schema

Source: `functions/src/pid_verification.ts`, `pidDcql`.
Reference: https://bmi.usercontent.opencode.de/eudi-wallet/developer-guide/resources/pid_reference/

| Requested item | Official German SD-JWT PID | Comparison |
| --- | --- | --- |
| VCT `urn:eudi:pid:de:1` | `urn:eudi:pid:de:1` | Matches logged stored type |
| `given_name` | `given_name` | Correct top-level path |
| `family_name` | `family_name` | Correct top-level path |
| `birthdate` | `birthdate` | Correct top-level path |
| `address.street_address` | `address.street_address` | Correct nested path |
| `address.postal_code` | `address.postal_code` | Correct nested path |
| `address.locality` | `address.locality` | Correct nested path |
| `address.country` | `address.country` | Correct nested path |

Matching the schema does not establish that every requested address attribute is
present in this particular credential. The reported failure is on `given_name`,
which the reference describes as mandatory.

## Limits and next diagnostic

The log omits the authorization JWT body and does not expose the stored
credential's decoded claim/disclosure structure. This compares the repository
query and logged credential type with the schema, not the full live request with
the full credential. There is no evidence supporting a claim-path rename.

Check whether the iPhone wallet's PID details display the given name. If they do,
investigate the iOS SD-JWT disclosure/claim-matching path; display alone does not
prove that presentation matching uses the same credential representation. If
they do not, investigate issuance and storage. To settle the structural question,
collect claim paths and format metadata from a supported wallet diagnostic or an
instrumented development build, without exporting identity values, complete
credentials, private keys, or tokens. A controlled fresh-issuance test may help
isolate an older stored-credential problem; the August issuance date alone does
not prove the credential is stale or invalid.
