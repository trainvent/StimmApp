/*
 Copyright (c) 2026 European Commission

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

// Isolated candidate-index reproduction, not a full wallet integration test.
// DefaultDcqlQueryable and makeCredentialMap copied from:
// https://github.com/german-national-wallet/de-eudi-lib-ios-wallet-kit
// revision 01d673c8804be1254b1e29c9cc66cddc822af216.
// Minimal model stubs cover only the exact top-level claim path used here.
// Run: xcrun swift -module-cache-path /tmp/stimmapp-swift-module-cache docs/developer/diagnostics/eudi_wallet_candidate_repro.swift
import Foundation
public enum Document { public typealias ID = String }
public typealias DocType = String
public enum DocDataFormat { case sdjwt, cbor }
public struct ClaimPath: Hashable {
 public var value: [String]
 public func contains2(_ other: ClaimPath) -> Bool { zip(value, other.value).allSatisfy { $0 == $1 } }
}
public protocol DcqlQueryable {
	/// retrieve credential identifiers matching docType and dataFormat
	func getCredentials(docOrVctType: DocType, docDataFormat: DocDataFormat) -> [Document.ID]
	/// retrieve all claim paths for a given credential identifier
	func getAllClaimPaths(id: Document.ID) -> [ClaimPath]
	/// check if a claim exists for a given credential identifier and claim path
	func hasClaim(id: Document.ID, claimPath: ClaimPath) -> Bool
	/// check if a claim exists for a given credential identifier and claim path and value
	func hasClaimWithValue(id: Document.ID, claimPath: ClaimPath, values: [String]) -> Bool
}

public class DefaultDcqlQueryable: DcqlQueryable {
	private let credentials: [Document.ID: (docType: DocType, format: DocDataFormat)]
	private let claimPaths: [Document.ID: [ClaimPath]]
	private let claimValues: [Document.ID: [ClaimPath: [String]]]

	public init(credentials: [Document.ID: (DocType, DocDataFormat)], claimPaths: [Document.ID: [ClaimPath]], claimValues: [Document.ID: [ClaimPath: [String]]] = [:]) {
		self.credentials = credentials
		self.claimPaths = claimPaths
		self.claimValues = claimValues
	}

	public func getCredentials(docOrVctType: DocType, docDataFormat: DocDataFormat) -> [Document.ID] {
		credentials.filter { _, value in
			value.docType == docOrVctType && value.format == docDataFormat
		}.map { $0.key }
	}

	public func getAllClaimPaths(id: Document.ID) -> [ClaimPath] {
		claimPaths[id] ?? []
	}

	public func hasClaim(id: Document.ID, claimPath: ClaimPath) -> Bool {
		guard let paths = claimPaths[id] else { return false }
		return paths.contains { $0.value == claimPath.value || claimPath.contains2($0) }
	}

	public func hasClaimWithValue(id: Document.ID, claimPath: ClaimPath, values: [String]) -> Bool {
		guard let claimValueMap = claimValues[id] else { return false }
		// Use contains2 for wildcard-aware matching (e.g., allArrayElements matches any element)
		// instead of exact ClaimPath dictionary lookup
		for (storedPath, availableValues) in claimValueMap {
			if storedPath.value == claimPath.value || claimPath.contains2(storedPath) {
				if values.contains(where: { availableValues.contains($0) }) {
					return true
				}
			}
		}
		return false
	}
}

enum Utils {
	static func makeCredentialMap(idsToDocTypes: [Document.ID: DocType], formatsRequested: [DocType: DocDataFormat]) -> [Document.ID: (DocType, DocDataFormat)] {
		var credentialMap = [Document.ID: (DocType, DocDataFormat)]()
		for (docId, docType) in idsToDocTypes {
			if let format = formatsRequested[docType] {
				credentialMap[docId] = (docType, format)
			}
		}
		return credentialMap
	}

}

let docId = "synthetic-pid"
let vct = "urn:eudi:pid:de:1"
let ids = [docId: vct]
let formats = [vct: DocDataFormat.sdjwt]
let givenName = ClaimPath(value: ["given_name"])
let candidates = Utils.makeCredentialMap(idsToDocTypes: ids, formatsRequested: formats)
let healthy = DefaultDcqlQueryable(credentials: candidates, claimPaths: [docId: [givenName]])
precondition(healthy.hasClaim(id: docId, claimPath: givenName))
// Presentation bytes removed by eligibility filtering; metadata retained by SDK.
let excluded = DefaultDcqlQueryable(credentials: candidates, claimPaths: [:])
precondition(excluded.getCredentials(docOrVctType: vct, docDataFormat: .sdjwt) == [docId])
precondition(!excluded.hasClaim(id: docId, claimPath: givenName))
// Synchronizing candidate metadata with eligible bytes prevents the ghost candidate.
let eligibleData: [String: Data] = [:]
let filtered = Utils.makeCredentialMap(idsToDocTypes: ids.filter { eligibleData[$0.key] != nil }, formatsRequested: formats)
let fixed = DefaultDcqlQueryable(credentials: filtered, claimPaths: [:])
precondition(fixed.getCredentials(docOrVctType: vct, docDataFormat: .sdjwt).isEmpty)
print("PASS: present claim matches; excluded credential remains a false candidate; eligible-only metadata removes it.")
