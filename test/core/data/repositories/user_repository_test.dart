import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

import 'user_repository_test.mocks.dart';

void main() {
  late UserRepository userRepository;
  late FakeFirebaseFirestore fakeFirebaseFirestore;
  late DatabaseService firestoreService;
  late MockFirebaseStorage mockFirebaseStorage;
  setUp(() {
    fakeFirebaseFirestore = FakeFirebaseFirestore();
    mockFirebaseStorage = MockFirebaseStorage();

    locator.setDatabaseForTest(fakeFirebaseFirestore);
    locator.setStorageForTest(mockFirebaseStorage);
    firestoreService = DatabaseService(fakeFirebaseFirestore);
    userRepository = UserRepository(firestoreService);
  });

  group('UserRepository', () {
    final tUserProfile = UserProfile(
      uid: '1',
      displayName: 'Test User',
      email: 'test@example.com',
      state: 'Bayern',
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
    );

    test('upsert and getById work correctly', () async {
      await userRepository.upsert(tUserProfile);
      final result = await userRepository.getById('1');

      expect(result, isNotNull);
      expect(result!.uid, tUserProfile.uid);
      expect(result.displayName, tUserProfile.displayName);
    });

    test('upsertWithUniqueUsername claims normalized username', () async {
      await userRepository.upsertWithUniqueUsername(
        tUserProfile.copyWith(displayName: 'Test User'),
      );

      final profile = await userRepository.getById('1');
      final usernameClaim = await fakeFirebaseFirestore
          .collection(DatabaseCollections.usernames)
          .doc('test user')
          .get();

      expect(profile?.displayName, 'Test User');
      expect(profile?.usernameKey, 'test user');
      expect(usernameClaim.data()?['uid'], '1');
      expect(usernameClaim.data()?['displayName'], 'Test User');
    });

    test('upsertWithUniqueUsername rejects duplicate username', () async {
      await userRepository.upsertWithUniqueUsername(
        tUserProfile.copyWith(uid: '1', displayName: 'Test User'),
      );

      expect(
        () => userRepository.upsertWithUniqueUsername(
          tUserProfile.copyWith(uid: '2', displayName: 'test user'),
        ),
        throwsA(
          isA<DatabaseException>().having(
            (error) => error.code,
            'code',
            'already-exists',
          ),
        ),
      );
    });

    test(
      'isUsernameAvailable returns true for an unclaimed username',
      () async {
        expect(await userRepository.isUsernameAvailable('New User'), isTrue);
      },
    );

    test('isUsernameAvailable returns false for another user claim', () async {
      await userRepository.upsertWithUniqueUsername(tUserProfile);

      expect(
        await userRepository.isUsernameAvailable(' test user ', forUserId: '2'),
        isFalse,
      );
    });

    test('isUsernameAvailable accepts the current user claim', () async {
      await userRepository.upsertWithUniqueUsername(tUserProfile);

      expect(
        await userRepository.isUsernameAvailable('TEST USER', forUserId: '1'),
        isTrue,
      );
    });

    test('delete removes the user', () async {
      await userRepository.upsert(tUserProfile);
      var result = await userRepository.getById('1');
      expect(result, isNotNull);

      await userRepository.delete('1');
      result = await userRepository.getById('1');
      expect(result, isNull);
    });

    test('watchById returns a stream of UserProfile', () {
      final stream = userRepository.watchById('1');

      expectLater(
        stream,
        emitsInOrder([
          isNull,
          predicate<UserProfile?>((p) => p != null && p.uid == '1'),
        ]),
      );

      userRepository.upsert(tUserProfile);
    });

    test('watchAll returns a stream of list of UserProfile', () async {
      final stream = userRepository.watchAll();

      expect(stream, emits(isEmpty));

      await userRepository.upsert(tUserProfile);

      expect(
        stream,
        emits(
          predicate<List<UserProfile>>(
            (list) => list.isNotEmpty && list.first.uid == '1',
          ),
        ),
      );
    });

    test('isAdmin is true for service@trainvent.com', () {
      const admin = UserProfile(uid: 'admin', email: 'service@trainvent.com');
      expect(admin.isAdmin, isTrue);
    });

    test('isAdmin is false for other emails', () {
      const user = UserProfile(uid: 'user', email: 'user@test.com');
      expect(user.isAdmin, isFalse);
    });
  });
}
