import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';

const Object _unset = Object();

class UserProfile {
  final String uid;
  final String? displayName;
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
  final bool? sendCrashLogs;
  final bool? analyticsCollectionEnabled;
  final bool? adsConsentGranted;
  final DateTime? adsConsentUpdatedAt;
  final DateTime? acceptedCommunityRulesAt;

  // Settings
  final bool? showPetitionReason;
  final String? themeMode; // 'light', 'dark', or null (system)
  final String? themeScheme; // 'stimm', 'ocean', etc.
  final String? locale; // 'en', 'de', etc.

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

  bool get isAdmin => email == IConst.adminEmail;
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
    this.sendCrashLogs,
    this.analyticsCollectionEnabled,
    this.adsConsentGranted,
    this.adsConsentUpdatedAt,
    this.acceptedCommunityRulesAt,
    this.showPetitionReason,
    this.themeMode,
    this.themeScheme,
    this.locale,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
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
    bool? isVerified,
    DateTime? gotVerifiedAt,
    bool? sendCrashLogs,
    bool? analyticsCollectionEnabled,
    Object? adsConsentGranted = _unset,
    Object? adsConsentUpdatedAt = _unset,
    DateTime? acceptedCommunityRulesAt,
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
      isVerified: isVerified ?? this.isVerified,
      gotVerifiedAt: gotVerifiedAt ?? this.gotVerifiedAt,
      sendCrashLogs: sendCrashLogs ?? this.sendCrashLogs,
      analyticsCollectionEnabled:
          analyticsCollectionEnabled ?? this.analyticsCollectionEnabled,
      adsConsentGranted: identical(adsConsentGranted, _unset)
          ? this.adsConsentGranted
          : adsConsentGranted as bool?,
      adsConsentUpdatedAt: identical(adsConsentUpdatedAt, _unset)
          ? this.adsConsentUpdatedAt
          : adsConsentUpdatedAt as DateTime?,
      acceptedCommunityRulesAt:
          acceptedCommunityRulesAt ?? this.acceptedCommunityRulesAt,
      showPetitionReason: showPetitionReason ?? this.showPetitionReason,
      themeMode: themeMode ?? this.themeMode,
      themeScheme: themeScheme ?? this.themeScheme,
      locale: locale ?? this.locale,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, String uid) {
    final email = json['email'] as String?;
    final forcedPro = shouldForcePro(email);

    return UserProfile(
      uid: uid,
      displayName: json['displayName'] as String?,
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
      sendCrashLogs: json['sendCrashLogs'] as bool?,
      analyticsCollectionEnabled: json['analyticsCollectionEnabled'] as bool?,
      adsConsentGranted: json['adsConsentGranted'] as bool?,
      adsConsentUpdatedAt: (json['adsConsentUpdatedAt'] as Timestamp?)
          ?.toDate(),
      acceptedCommunityRulesAt: (json['acceptedCommunityRulesAt'] as Timestamp?)
          ?.toDate(),
      showPetitionReason: json['showPetitionReason'] as bool?,
      themeMode: json['themeMode'] as String?,
      themeScheme: json['themeScheme'] as String?,
      locale: json['locale'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'displayName': displayName,
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
      'sendCrashLogs': sendCrashLogs,
      'analyticsCollectionEnabled': analyticsCollectionEnabled,
      'adsConsentGranted': adsConsentGranted,
      'adsConsentUpdatedAt': adsConsentUpdatedAt != null
          ? Timestamp.fromDate(adsConsentUpdatedAt!)
          : null,
      'acceptedCommunityRulesAt': acceptedCommunityRulesAt != null
          ? Timestamp.fromDate(acceptedCommunityRulesAt!)
          : null,
      'showPetitionReason': showPetitionReason,
      'themeMode': themeMode,
      'themeScheme': themeScheme,
      'locale': locale,
    };
  }
}
