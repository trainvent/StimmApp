import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';

const Object _unset = Object();

const currentIdentityVerificationPolicyVersion = 'pid-profile-v1';

class UserProfile {
  final String uid;
  final String? displayName;
  final String? usernameKey;
  final String? email;
  final String? state;
  final String? countryCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isPro;
  final DateTime? wentProAt;
  final bool? subscribedToPro;
  final bool? isVerified;
  final DateTime? gotVerifiedAt;
  final DateTime? identityVerificationValidUntil;
  final String? identityVerificationPolicyVersion;
  final int identityRevision;
  final int? verifiedIdentityRevision;
  final List<String> identityVerificationVerifiedFields;
  final bool? sendCrashLogs;
  final bool? analyticsCollectionEnabled;
  final DateTime? acceptedCommunityRulesAt;
  final bool? isGoogleSyncActive;
  final DateTime? googleSyncLastAt;

  // Settings
  final bool? showPetitionReason;
  final String? themeMode; // 'light', 'dark', or null (system)
  final String? themeScheme; // 'stimm', 'ocean', etc.
  final String? locale; // 'en', 'de', etc.
  final bool hasLoadError;

  /// Returns the date when the subscription expires (30 days after purchase).
  DateTime? get subscriptionEndsAt {
    if (wentProAt == null) return null;
    return wentProAt!.add(const Duration(days: 30));
  }

  // ID Card Fields
  final String? surname;
  final String? givenName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? placeOfBirth;
  final DateTime? expiryDate;
  final String? idNumber;
  final String? address;
  final String? town;
  final String? height;

  bool get isAdmin {
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedAdminEmail = IConst.adminEmail.trim().toLowerCase();
    return normalizedEmail != null &&
        normalizedAdminEmail.isNotEmpty &&
        normalizedEmail == normalizedAdminEmail;
  }

  bool get supportsStateScope =>
      countryCode?.toUpperCase() == 'DE' ||
      (countryCode == null && state != null && state!.isNotEmpty);

  static bool shouldForcePro(String? email) {
    if (email == null) return false;
    return IConst.alwaysProEmails.contains(email.toLowerCase());
  }

  const UserProfile({
    required this.uid,
    this.displayName,
    this.usernameKey,
    this.email,
    this.state,
    this.countryCode,
    this.createdAt,
    this.updatedAt,
    this.surname,
    this.givenName,
    this.dateOfBirth,
    this.nationality,
    this.placeOfBirth,
    this.expiryDate,
    this.idNumber,
    this.address,
    this.town,
    this.height,
    this.isPro,
    this.wentProAt,
    this.subscribedToPro,
    this.isVerified,
    this.gotVerifiedAt,
    this.identityVerificationValidUntil,
    this.identityVerificationPolicyVersion,
    this.identityRevision = 0,
    this.verifiedIdentityRevision,
    this.identityVerificationVerifiedFields = const [],
    this.sendCrashLogs,
    this.analyticsCollectionEnabled,
    this.acceptedCommunityRulesAt,
    this.isGoogleSyncActive,
    this.googleSyncLastAt,
    this.showPetitionReason,
    this.themeMode,
    this.themeScheme,
    this.locale,
    this.hasLoadError = false,
  });

  const UserProfile.erroneous(String uid) : this(uid: uid, hasLoadError: true);

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? usernameKey,
    String? email,
    Object? state = _unset,
    Object? countryCode = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? surname,
    String? givenName,
    DateTime? dateOfBirth,
    String? nationality,
    String? placeOfBirth,
    DateTime? expiryDate,
    String? idNumber,
    String? address,
    String? town,
    String? height,
    bool? isPro,
    DateTime? wentProAt,
    bool? subscribedToPro,
    Object? isVerified = _unset,
    Object? gotVerifiedAt = _unset,
    Object? identityVerificationValidUntil = _unset,
    Object? identityVerificationPolicyVersion = _unset,
    int? identityRevision,
    Object? verifiedIdentityRevision = _unset,
    List<String>? identityVerificationVerifiedFields,
    bool? sendCrashLogs,
    bool? analyticsCollectionEnabled,
    DateTime? acceptedCommunityRulesAt,
    bool? isGoogleSyncActive,
    DateTime? googleSyncLastAt,
    bool? showPetitionReason,
    String? themeMode,
    String? themeScheme,
    String? locale,
  }) {
    final resolvedEmail = email ?? this.email;
    final forcedPro = shouldForcePro(resolvedEmail);

    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      usernameKey: usernameKey ?? this.usernameKey,
      email: resolvedEmail,
      state: identical(state, _unset) ? this.state : state as String?,
      countryCode: identical(countryCode, _unset)
          ? this.countryCode
          : countryCode as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      surname: surname ?? this.surname,
      givenName: givenName ?? this.givenName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      expiryDate: expiryDate ?? this.expiryDate,
      idNumber: idNumber ?? this.idNumber,
      address: address ?? this.address,
      town: town ?? this.town,
      height: height ?? this.height,
      isPro: forcedPro ? true : (isPro ?? this.isPro),
      wentProAt: wentProAt ?? this.wentProAt,
      subscribedToPro: subscribedToPro ?? this.subscribedToPro,
      isVerified: identical(isVerified, _unset)
          ? this.isVerified
          : isVerified as bool?,
      gotVerifiedAt: identical(gotVerifiedAt, _unset)
          ? this.gotVerifiedAt
          : gotVerifiedAt as DateTime?,
      identityVerificationValidUntil:
          identical(identityVerificationValidUntil, _unset)
          ? this.identityVerificationValidUntil
          : identityVerificationValidUntil as DateTime?,
      identityVerificationPolicyVersion:
          identical(identityVerificationPolicyVersion, _unset)
          ? this.identityVerificationPolicyVersion
          : identityVerificationPolicyVersion as String?,
      identityRevision: identityRevision ?? this.identityRevision,
      verifiedIdentityRevision: identical(verifiedIdentityRevision, _unset)
          ? this.verifiedIdentityRevision
          : verifiedIdentityRevision as int?,
      identityVerificationVerifiedFields:
          identityVerificationVerifiedFields ??
          this.identityVerificationVerifiedFields,
      sendCrashLogs: sendCrashLogs ?? this.sendCrashLogs,
      analyticsCollectionEnabled:
          analyticsCollectionEnabled ?? this.analyticsCollectionEnabled,
      acceptedCommunityRulesAt:
          acceptedCommunityRulesAt ?? this.acceptedCommunityRulesAt,
      isGoogleSyncActive: isGoogleSyncActive ?? this.isGoogleSyncActive,
      googleSyncLastAt: googleSyncLastAt ?? this.googleSyncLastAt,
      showPetitionReason: showPetitionReason ?? this.showPetitionReason,
      themeMode: themeMode ?? this.themeMode,
      themeScheme: themeScheme ?? this.themeScheme,
      locale: locale ?? this.locale,
      hasLoadError: hasLoadError,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    final email = json['email'] as String?;
    final forcedPro = shouldForcePro(email);

    return UserProfile(
      uid: uid,
      displayName: json['displayName'] as String?,
      usernameKey: json['usernameKey'] as String?,
      email: email,
      state: json['state'] as String?,
      countryCode: (json['countryCode'] as String?)?.toUpperCase(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      surname: json['surname'] as String?,
      givenName: json['givenName'] as String?,
      dateOfBirth: (json['dateOfBirth'] as Timestamp?)?.toDate(),
      nationality: json['nationality'] as String?,
      placeOfBirth: json['placeOfBirth'] as String?,
      expiryDate: (json['expiryDate'] as Timestamp?)?.toDate(),
      idNumber: json['idNumber'] as String?,
      address: json['address'] as String?,
      town: json['town'] as String? ?? json['city'] as String?,
      height: json['height'] as String?,
      isPro: forcedPro ? true : json['isPro'] as bool?,
      wentProAt: (json['wentProAt'] as Timestamp?)?.toDate(),
      subscribedToPro: json['subscribedToPro'] as bool?,
      isVerified: json['isVerified'] as bool?,
      gotVerifiedAt: (json['gotVerifiedAt'] as Timestamp?)?.toDate(),
      identityVerificationValidUntil:
          (json['identityVerificationValidUntil'] as Timestamp?)?.toDate(),
      identityVerificationPolicyVersion:
          json['identityVerificationPolicyVersion'] as String?,
      identityRevision: json['identityRevision'] as int? ?? 0,
      verifiedIdentityRevision: json['verifiedIdentityRevision'] as int?,
      identityVerificationVerifiedFields:
          (json['identityVerificationVerifiedFields'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
      sendCrashLogs: json['sendCrashLogs'] as bool?,
      analyticsCollectionEnabled: json['analyticsCollectionEnabled'] as bool?,
      acceptedCommunityRulesAt: (json['acceptedCommunityRulesAt'] as Timestamp?)
          ?.toDate(),
      isGoogleSyncActive: json['isGoogleSyncActive'] as bool?,
      googleSyncLastAt: (json['googleSyncLastAt'] as Timestamp?)?.toDate(),
      showPetitionReason: json['showPetitionReason'] as bool?,
      themeMode: json['themeMode'] as String?,
      themeScheme: json['themeScheme'] as String?,
      locale: json['locale'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'displayName': displayName,
      'usernameKey': usernameKey,
      'email': email,
      'state': state,
      'countryCode': countryCode?.toUpperCase(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'surname': surname,
      'givenName': givenName,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'nationality': nationality,
      'placeOfBirth': placeOfBirth,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'idNumber': idNumber,
      'address': address,
      'town': town,
      'height': height,
      'isPro': shouldForcePro(email) ? true : isPro,
      'wentProAt': wentProAt != null ? Timestamp.fromDate(wentProAt!) : null,
      'subscribedToPro': subscribedToPro,
      'isVerified': isVerified,
      'gotVerifiedAt': gotVerifiedAt,
      'identityVerificationValidUntil': identityVerificationValidUntil,
      'identityVerificationPolicyVersion': identityVerificationPolicyVersion,
      'identityRevision': identityRevision,
      'verifiedIdentityRevision': verifiedIdentityRevision,
      'identityVerificationVerifiedFields': identityVerificationVerifiedFields,
      'sendCrashLogs': sendCrashLogs,
      'analyticsCollectionEnabled': analyticsCollectionEnabled,
      'acceptedCommunityRulesAt': acceptedCommunityRulesAt != null
          ? Timestamp.fromDate(acceptedCommunityRulesAt!)
          : null,
      'isGoogleSyncActive': isGoogleSyncActive,
      'googleSyncLastAt': googleSyncLastAt != null
          ? Timestamp.fromDate(googleSyncLastAt!)
          : null,
      'showPetitionReason': showPetitionReason,
      'themeMode': themeMode,
      'themeScheme': themeScheme,
      'locale': locale,
    };
  }

  bool hasValidIdentityVerificationAt(DateTime now) {
    final validUntil = identityVerificationValidUntil;
    return isVerified == true &&
        identityVerificationPolicyVersion ==
            currentIdentityVerificationPolicyVersion &&
        validUntil != null &&
        validUntil.isAfter(now) &&
        verifiedIdentityRevision != null &&
        verifiedIdentityRevision == identityRevision;
  }

  bool get hasValidIdentityVerification =>
      hasValidIdentityVerificationAt(DateTime.now());

  bool get hasIdentityVerificationHistory =>
      isVerified == true || gotVerifiedAt != null;
}
