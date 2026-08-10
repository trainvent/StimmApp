import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/google_auth_client.dart';
import 'package:stimmapp/core/data/services/google_profile_sync_service.dart';
import 'package:stimmapp/core/data/services/tomtom_search_service.dart';

class _SyncAuthService extends AuthService {
  @override
  String? get authenticatedEmail => 'google@example.com';

  @override
  Future<GoogleProfileData> importGoogleProfileData({
    bool promptIfNecessary = true,
  }) async => GoogleProfileData(
    givenName: 'Google',
    surname: 'Person',
    email: 'google@example.com',
    dateOfBirth: DateTime(1990, 1, 2),
    address: 'Main Street 1, Berlin',
  );
}

class _RecordingUserRepository extends UserRepository {
  _RecordingUserRepository() : super(DatabaseService(FakeFirebaseFirestore()));

  UserProfile? upsertedProfile;
  var uniqueUsernameUpsertCalled = false;

  @override
  Future<void> upsert(UserProfile profile) async {
    upsertedProfile = profile;
  }

  @override
  Future<void> upsertWithUniqueUsername(UserProfile profile) async {
    uniqueUsernameUpsertCalled = true;
  }
}

class _ResolvedAddressService extends TomTomSearchService {
  _ResolvedAddressService() : super('test-key');

  @override
  Future<PlaceAddressInfo> resolveAddress(
    String query, {
    List<String>? countries,
  }) async => const PlaceAddressInfo(
    town: 'Berlin',
    state: 'Berlin',
    countryCode: 'DE',
  );
}

void main() {
  test('sync preserves username claim without opening a transaction', () async {
    final users = _RecordingUserRepository();
    final service = GoogleProfileSyncService(
      auth: _SyncAuthService(),
      users: users,
      addresses: _ResolvedAddressService(),
    );
    const profile = UserProfile(
      uid: 'user-1',
      displayName: 'Original Username',
      usernameKey: 'original username',
      email: 'old@example.com',
    );

    final result = await service.synchronize(profile: profile, activate: true);

    expect(users.uniqueUsernameUpsertCalled, isFalse);
    expect(users.upsertedProfile, same(result));
    expect(result.displayName, 'Original Username');
    expect(result.usernameKey, 'original username');
    expect(result.isGoogleSyncActive, isTrue);
    expect(result.email, 'google@example.com');
  });
}
