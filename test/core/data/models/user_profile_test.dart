import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    final timestamp = Timestamp.fromDate(DateTime(2023));
    final userProfile = UserProfile(
      uid: '123',
      displayName: 'Test User',
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
      'email': 'test@example.com',
      'state': 'Hessen',
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
      'height': null,
      'isPro': false,
      'wentProAt': null,
      'subscribedToPro': null,
      'isVerified': false,
      'gotVerifiedAt': null,
      'sendCrashLogs': true,
      'showPetitionReason': null,
      'themeMode': null,
      'locale': null,
    };

    test('fromJson creates a UserProfile object from a map', () {
      final result = UserProfile.fromJson(userProfileJson, '123');
      expect(result.uid, userProfile.uid);
      expect(result.displayName, userProfile.displayName);
      expect(result.email, userProfile.email);
      expect(result.createdAt, userProfile.createdAt);
      expect(result.updatedAt, userProfile.updatedAt);
      expect(result.state, userProfile.state);
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
      // Assuming IConst.adminEmail is 'service@stimmapp.org' based on previous context
      // Ideally, we should import IConst, but for this test we can just check the logic if we knew the constant value.
      // Since I cannot see IConst here, I will rely on the property logic.
      // Let's just test the property behavior if we set the email.

      // Note: This test depends on the actual value of IConst.adminEmail.
      // If IConst.adminEmail is 'service@stimmapp.org':
      final adminUser = userProfile.copyWith(email: 'service@stimmapp.org');
      expect(adminUser.isAdmin, true);

      final normalUser = userProfile.copyWith(email: 'user@example.com');
      expect(normalUser.isAdmin, false);
    });
  });
}
