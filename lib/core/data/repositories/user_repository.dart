import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';

import 'petition_repository.dart';
import 'poll_repository.dart';
import 'survey_repository.dart';
import 'user_interface.dart';

const _verifiedIdentityFieldNames = <String>{
  'givenName',
  'surname',
  'dateOfBirth',
  'address',
  'town',
  'countryCode',
};

const _serverVerificationFieldNames = <String>{
  'isVerified',
  'gotVerifiedAt',
  'identityVerificationValidUntil',
  'identityVerificationPolicyVersion',
  'identityRevision',
  'verifiedIdentityRevision',
  'identityVerificationVerifiedFields',
};

class UserRepository implements UserInterface {
  UserRepository(this._fs);

  final DatabaseService _fs;

  static UserRepository create() => UserRepository(locator.databaseService);

  static Future<UserProfile?> currentUser() {
    final uid = locator.authService.currentUser?.uid;
    if (uid == null) {
      return Future.value(null);
    }
    return create().getById(uid);
  }

  CollectionReference<UserProfile> _col() {
    return _fs.colRef<UserProfile>(
      DatabaseCollections.users,
      fromFirestore: (snap, _) =>
          UserProfile.fromJson(snap.data() as Map<String, dynamic>, snap.id),
      toFirestore: (model, _) => model.toJson(),
    );
  }

  DocumentReference<UserProfile> _doc(String uid) {
    return _col().doc(uid);
  }

  @override
  Future<UserProfile?> getById(String uid) async {
    return _fs.getDoc(_doc(uid));
  }

  Future<bool?> getPersistedProStatus(String uid) async {
    final snapshot = await _fs.instance
        .collection(DatabaseCollections.users)
        .doc(uid)
        .get();
    return snapshot.data()?['isPro'] as bool?;
  }

  @override
  Future<void> upsert(UserProfile profile) async {
    final profileRef = _doc(profile.uid);
    try {
      await _fs.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(profileRef);
        final nextProfile = _profileForClientWrite(
          snapshot.data(),
          profile,
        ).copyWith(updatedAt: DateTime.now());
        transaction.set(profileRef, nextProfile, SetOptions(merge: true));
      });
    } on FirebaseException catch (error) {
      throw DatabaseException(error);
    }
  }

  bool _identityChanged(UserProfile before, UserProfile after) {
    return before.givenName != after.givenName ||
        before.surname != after.surname ||
        before.dateOfBirth != after.dateOfBirth ||
        before.address != after.address ||
        before.town != after.town ||
        before.countryCode?.toUpperCase() != after.countryCode?.toUpperCase();
  }

  UserProfile _profileForClientWrite(
    UserProfile? existing,
    UserProfile requested,
  ) {
    if (existing == null) {
      return requested.copyWith(
        isVerified: false,
        gotVerifiedAt: null,
        identityVerificationValidUntil: null,
        identityVerificationPolicyVersion: null,
        identityRevision: 0,
        verifiedIdentityRevision: null,
        identityVerificationVerifiedFields: const [],
      );
    }

    final identityChanged = _identityChanged(existing, requested);
    return requested.copyWith(
      isVerified: identityChanged ? false : existing.isVerified,
      gotVerifiedAt: existing.gotVerifiedAt,
      identityVerificationValidUntil: existing.identityVerificationValidUntil,
      identityVerificationPolicyVersion:
          existing.identityVerificationPolicyVersion,
      identityRevision: existing.identityRevision + (identityChanged ? 1 : 0),
      verifiedIdentityRevision: existing.verifiedIdentityRevision,
      identityVerificationVerifiedFields:
          existing.identityVerificationVerifiedFields,
    );
  }

  Future<bool> isUsernameAvailable(String username, {String? forUserId}) async {
    if (!hasValidUsernameLength(username)) return false;
    final usernameKey = usernameKeyFor(username);

    try {
      final snapshot = await _fs.instance
          .collection(DatabaseCollections.usernames)
          .doc(usernameKey)
          .get();
      if (!snapshot.exists) return true;

      return forUserId != null && snapshot.data()?['uid'] == forUserId;
    } on FirebaseException catch (e) {
      throw DatabaseException(e);
    }
  }

  Future<UserProfile?> getByUsername(String username) async {
    if (!hasValidUsernameLength(username)) return null;
    final usernameKey = usernameKeyFor(username);

    try {
      final usernameSnapshot = await _fs.instance
          .collection(DatabaseCollections.usernames)
          .doc(usernameKey)
          .get();
      final uid = usernameSnapshot.data()?['uid'] as String?;
      if (uid == null || uid.isEmpty) return null;
      return getById(uid);
    } on FirebaseException catch (e) {
      throw DatabaseException(e);
    }
  }

  Future<void> upsertWithUniqueUsername(UserProfile profile) async {
    final displayName = normalizeUsername(profile.displayName ?? '');
    if (!hasValidUsernameLength(displayName)) {
      throw DatabaseException(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message:
              'Username must be at least ${AppLimits.minUsernameLength} characters long.',
        ),
      );
    }

    final usernameKey = usernameKeyFor(displayName);
    final profileRef = _doc(profile.uid);
    final usernameRef = _fs.instance
        .collection(DatabaseCollections.usernames)
        .doc(usernameKey);

    try {
      await _fs.instance.runTransaction((transaction) async {
        final usernameSnap = await transaction.get(usernameRef);
        final usernameOwner = usernameSnap.data()?['uid'] as String?;
        if (usernameSnap.exists && usernameOwner != profile.uid) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'already-exists',
            message: 'Username is already taken.',
          );
        }

        final existingProfileSnap = await transaction.get(profileRef);
        final existingProfile = existingProfileSnap.data();
        final previousUsernameKey = existingProfile?.usernameKey;
        if (previousUsernameKey != null &&
            previousUsernameKey.isNotEmpty &&
            previousUsernameKey != usernameKey) {
          transaction.delete(
            _fs.instance
                .collection(DatabaseCollections.usernames)
                .doc(previousUsernameKey),
          );
        }

        final updatedProfile = _profileForClientWrite(existingProfile, profile)
            .copyWith(
              displayName: displayName,
              usernameKey: usernameKey,
              updatedAt: DateTime.now(),
            );
        transaction.set(profileRef, updatedProfile, SetOptions(merge: true));
        transaction.set(usernameRef, <String, Object?>{
          'uid': profile.uid,
          'displayName': displayName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e);
    }
  }

  Future<void> update(String uid, Map<String, dynamic> data) async {
    final reference = _fs.instance
        .collection(DatabaseCollections.users)
        .doc(uid);
    final sanitized = Map<String, dynamic>.from(data)
      ..removeWhere((key, _) => _serverVerificationFieldNames.contains(key));

    try {
      await _fs.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        final existing = snapshot.data() ?? const <String, dynamic>{};
        final identityChanged = sanitized.entries.any(
          (entry) =>
              _verifiedIdentityFieldNames.contains(entry.key) &&
              existing[entry.key] != entry.value,
        );
        if (identityChanged) {
          final currentRevision = existing['identityRevision'] as int? ?? 0;
          sanitized
            ..['isVerified'] = false
            ..['identityRevision'] = currentRevision + 1;
        }
        transaction.update(reference, sanitized);
      });
    } on FirebaseException catch (error) {
      throw DatabaseException(error);
    }
  }

  @override
  Future<void> delete(String uid) async {
    final profile = await getById(uid);

    // Use repository helpers to remove user activity and close created items.
    final pollRepo = PollRepository.create();
    final petitionRepo = PetitionRepository.create();
    final surveyRepo = SurveyRepository.create();

    // Remove votes and signatures (decrements counts and removes subdocs)
    await pollRepo.removeVotesByUser(uid);
    await petitionRepo.removeSignaturesByUser(uid);
    await surveyRepo.removeResponsesByUser(uid);

    // Delete the user profile document
    await _fs.delete(_doc(uid));
    if (profile?.usernameKey != null && profile!.usernameKey!.isNotEmpty) {
      await _fs.delete(
        _fs.instance
            .collection(DatabaseCollections.usernames)
            .doc(profile.usernameKey!),
      );
    }

    // Delete profile picture from storage
    try {
      await locator.storageService.deleteProfilePicture(uid);
    } catch (e) {
      // In tests where Firebase Storage might not be initialized, or if it fails,
      // we log but don't fail the whole user deletion.
      debugPrint('Error deleting profile picture: $e');
    }

    // Close polls and petitions created by this user
    await pollRepo.closePollsCreatedByUser(uid);
    await petitionRepo.closePetitionsCreatedByUser(uid);
    await surveyRepo.closeSurveysCreatedByUser(uid);
  }

  @override
  Stream<UserProfile?> watchById(String uid) {
    return _fs.watchDoc(_doc(uid));
  }

  @override
  Stream<List<UserProfile>> watchAll({int? limit}) {
    return _fs.watchCol(_col(), limit: limit);
  }
}
