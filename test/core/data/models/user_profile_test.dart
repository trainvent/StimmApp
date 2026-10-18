import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    final timestamp = Timestamp.fromDate(DateTime(2023));
    final userProfile = UserProfile(
      uid: '123',
      displayName: 'Test User',
      usernameKey: 'test user',
      state: 'Hessen',
      email: 'test@example.com',
      createdAt: timestamp.toDate(),
      updatedAt: timestamp.toDate(),
      isPro: false,
      isVerified: false,
      sendCrashLogs: true,
    );

    final userProfileJson = {
      'displayName': 'Test User',
      'profilePictureUrl': null,
      'websiteUrl': null,
      'usernameKey': 'test user',
      'email': 'test@example.com',
      'state': 'Hessen',
      'countryCode': null,
      'createdAt': timestamp,
      'updatedAt': timestamp,
      'surname': null,
      'givenName': null,
      'dateOfBirth': null,
      'nationality': null,
      'placeOfBirth': null,
      'expiryDate': null,
      'idNumber': null,
      'address': null,
      'town': null,
      'height': null,
      'isPro': false,
      'wentProAt': null,
      'subscribedToPro': null,
      'isVerified': false,
      'gotVerifiedAt': null,
      'sendCrashLogs': true,
      'analyticsCollectionEnabled': null,
      'acceptedCommunityRulesAt': null,
      'isGoogleSyncActive': null,
      'googleSyncLastAt': null,
      'showPetitionReason': null,
      'signAnonymously': false,
      'hidePublications': false,
      'publicProfileShowFullName': false,
      'publicProfileShowAddress': false,
      'publicProfileShowLink': false,
      'themeMode': null,
      'themeScheme': null,
      'locale': null,
    };

    test('profile links survive edits and can be explicitly removed', () {
      final linked = userProfile.copyWith(websiteUrl: 'https://example.org/me');
      expect(
        UserProfile.fromJson(linked.toJson(), linked.uid).websiteUrl,
        'https://example.org/me',
      );
      expect(
        linked.copyWith(givenName: 'Updated').websiteUrl,
        'https://example.org/me',
      );
      expect(linked.copyWith(websiteUrl: null).toJson()['websiteUrl'], isNull);
    });

    test(
      'publication privacy defaults to visible and survives other edits',
      () {
        expect(UserProfile.fromJson({}, 'default').hidePublications, isFalse);
        final hidden = userProfile.copyWith(
          hidePublications: true,
          publicProfileShowFullName: true,
          publicProfileShowAddress: true,
          publicProfileShowLink: true,
        );
        final restored = UserProfile.fromJson(hidden.toJson(), hidden.uid);
        expect(restored.publicProfileShowFullName, isTrue);
        expect(restored.publicProfileShowAddress, isTrue);
        expect(restored.publicProfileShowLink, isTrue);
        expect(
          hidden.copyWith(givenName: 'Changed').publicProfileShowAddress,
          isTrue,
        );
        expect(
          UserProfile.fromJson(hidden.toJson(), hidden.uid).hidePublications,
          isTrue,
        );
        expect(hidden.copyWith(givenName: 'Changed').hidePublications, isTrue);
        expect(
          hidden.copyWith(hidePublications: false).hidePublications,
          isFalse,
        );
      },
    );

    test('anonymous signing defaults off and survives round trips', () {
      expect(UserProfile.fromJson({}, 'legacy').signAnonymously, isFalse);
      final anonymous = userProfile.copyWith(signAnonymously: true);
      expect(
        UserProfile.fromJson(anonymous.toJson(), anonymous.uid).signAnonymously,
        isTrue,
      );
      expect(
        anonymous.copyWith(displayName: 'Changed').signAnonymously,
        isTrue,
      );
      expect(
        anonymous.copyWith(signAnonymously: false).signAnonymously,
        isFalse,
      );
    });

    test('fromJson creates a UserProfile object from a map', () {
      final result = UserProfile.fromJson(userProfileJson, '123');
      expect(result.uid, userProfile.uid);
      expect(result.displayName, userProfile.displayName);
      expect(result.email, userProfile.email);
      expect(result.createdAt, userProfile.createdAt);
      expect(result.updatedAt, userProfile.updatedAt);
      expect(result.state, userProfile.state);
      expect(result.countryCode, userProfile.countryCode);
      expect(result.idNumber, userProfile.idNumber);
      expect(result.isPro, userProfile.isPro);
      expect(result.wentProAt, userProfile.wentProAt);
      expect(result.subscribedToPro, userProfile.subscribedToPro);
      expect(result.isVerified, userProfile.isVerified);
      expect(result.gotVerifiedAt, userProfile.gotVerifiedAt);
      expect(result.sendCrashLogs, userProfile.sendCrashLogs);
    });

    test('toJson returns a map from a UserProfile object', () {
      final result = userProfile.toJson();
      expect(result, userProfileJson);
    });

    test('copyWith creates a copy with updated fields', () {
      final updated = userProfile.copyWith(
        displayName: 'New Name',
        sendCrashLogs: false,
      );

      expect(updated.uid, userProfile.uid);
      expect(updated.displayName, 'New Name');
      expect(updated.sendCrashLogs, false);
      expect(updated.email, userProfile.email); // Should remain unchanged
    });

    test('subscriptionEndsAt returns correct date', () {
      final proUser = userProfile.copyWith(wentProAt: DateTime(2023, 1, 1));
      expect(
        proUser.subscriptionEndsAt,
        DateTime(2023, 1, 31),
      ); // 30 days later

      final nonProUser = userProfile.copyWith(wentProAt: null);
      expect(nonProUser.subscriptionEndsAt, null);
    });

    test('isAdmin returns true for admin email', () {
      final adminUser = userProfile.copyWith(email: 'SERVICE@TRAINVENT.COM');
      expect(adminUser.isAdmin, true);

      final normalUser = userProfile.copyWith(email: 'user@example.com');
      expect(normalUser.isAdmin, false);
    });
  });
}
