import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/providers/subscription_provider.dart';
import 'package:stimmapp/core/services/purchases_service.dart';

void main() {
  test('forced-Pro Auth email survives a basic RevenueCat status', () async {
    final firestore = FakeFirebaseFirestore();
    final forcedProEmail = IConst.ownerEmail.isNotEmpty
        ? IConst.ownerEmail
        : IConst.adminEmail;
    locator.setDatabaseForTest(firestore);
    await firestore.collection(DatabaseCollections.users).doc('owner-1').set({
      'email': forcedProEmail,
      'isPro': false,
    });

    await syncSubscriptionStatus(
      'owner-1',
      EntitlementTier.basic,
      authenticatedEmail: forcedProEmail,
    );

    final user = await firestore
        .collection(DatabaseCollections.users)
        .doc('owner-1')
        .get();
    expect(user.data()?['isPro'], isTrue);
  });
}
