import 'package:cloud_firestore/cloud_firestore.dart';
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
  final now = DateTime.utc(2026, 8, 9, 12);
  late FakeFirebaseFirestore firestore;
  late _FakeFirebaseAuth auth;
  late PublishingQuotaService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    auth = _FakeFirebaseAuth(const _FakeUser());
    service = PublishingQuotaService.forTest(
      firestore: firestore,
      auth: auth,
      now: () => now,
    );
    await firestore.collection(DatabaseCollections.users).doc('creator').set({
      'email': 'creator@example.com',
      'isPro': false,
    });
  });

  Future<DocumentReference<Map<String, dynamic>>> createPublication(
    String collection, {
    DateTime? createdAt,
  }) {
    return firestore.collection(collection).add({
      'createdBy': 'creator',
      'createdAt': Timestamp.fromDate(createdAt ?? now),
    });
  }

  test('quota is backed by publications that currently exist today', () async {
    final petition = await createPublication(DatabaseCollections.petitions);
    final poll = await createPublication(DatabaseCollections.polls);

    var status = await service.getDailyStatus();
    expect(status.canCreatePetition, isFalse);
    expect(status.canCreatePoll, isFalse);

    await petition.delete();
    await poll.delete();

    status = await service.getDailyStatus();
    expect(status.canCreatePetition, isTrue);
    expect(status.canCreatePoll, isTrue);
  });

  test('polls and surveys share one daily free allowance', () async {
    await createPublication(DatabaseCollections.surveys);

    final status = await service.getDailyStatus();
    expect(status.canCreatePetition, isTrue);
    expect(status.canCreatePoll, isFalse);
    await expectLater(
      service.ensureCanCreatePoll(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'poll_daily_limit_reached',
        ),
      ),
    );
  });

  test('failed attempts and legacy counters do not consume quota', () async {
    await firestore
        .collection(DatabaseCollections.users)
        .doc('creator')
        .collection('dailyPublishing')
        .doc('2026-08-09')
        .set({'petitionCount': 99, 'pollCount': 99});

    await service.ensureCanCreatePetition();
    await service.ensureCanCreatePoll();

    final status = await service.getDailyStatus();
    expect(status.canCreatePetition, isTrue);
    expect(status.canCreatePoll, isTrue);
  });

  test('publications from another UTC day do not consume quota', () async {
    await createPublication(
      DatabaseCollections.petitions,
      createdAt: DateTime.utc(2026, 8, 8, 23, 59),
    );
    await createPublication(
      DatabaseCollections.polls,
      createdAt: DateTime.utc(2026, 8, 10),
    );

    final status = await service.getDailyStatus();
    expect(status.canCreatePetition, isTrue);
    expect(status.canCreatePoll, isTrue);
  });

  test('Pro users are not limited by existing publications', () async {
    await firestore.collection(DatabaseCollections.users).doc('creator').set({
      'email': 'creator@example.com',
      'isPro': true,
    });
    await createPublication(DatabaseCollections.petitions);
    await createPublication(DatabaseCollections.polls);
    await createPublication(DatabaseCollections.surveys);

    final status = await service.getDailyStatus();
    expect(status.canCreatePetition, isTrue);
    expect(status.canCreatePoll, isTrue);
  });
}
