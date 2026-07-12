import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/services/publishing_quota_service.dart';

class _FakeFirebaseAuth extends Mock implements FirebaseAuth {
  _FakeFirebaseAuth(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;
}

class _FakeUser implements User {
  const _FakeUser();

  @override
  String get uid => 'creator';

  @override
  String? get email => 'creator@example.com';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _FakeFirebaseAuth auth;
  late PublishingQuotaService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = _FakeFirebaseAuth(const _FakeUser());
    service = PublishingQuotaService.forTest(firestore: firestore, auth: auth);
  });

  test('free users are limited to one petition and one poll per day', () async {
    await firestore.collection(DatabaseCollections.users).doc('creator').set({
      'email': 'creator@example.com',
      'isPro': false,
    });

    await service.incrementPetition();
    await service.incrementPoll();

    await expectLater(
      service.incrementPetition(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'petition_daily_limit_reached',
        ),
      ),
    );
    await expectLater(
      service.incrementPoll(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'poll_daily_limit_reached',
        ),
      ),
    );

    final status = await service.getDailyStatus();
    expect(status.canCreatePetition, isFalse);
    expect(status.canCreatePoll, isFalse);
  });

  test('Pro users keep publishing even after free daily limits', () async {
    await firestore.collection(DatabaseCollections.users).doc('creator').set({
      'email': 'creator@example.com',
      'isPro': true,
    });

    await service.incrementPetition();
    await service.incrementPetition();
    await service.incrementPoll();
    await service.incrementPoll();

    final status = await service.getDailyStatus();
    expect(status.canCreatePetition, isTrue);
    expect(status.canCreatePoll, isTrue);
  });
}
