import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/functions/normalize_username.dart';

import 'petition_repository.dart';
import 'poll_repository.dart';
import 'survey_repository.dart';

class UserRepository {
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

  Future<void> upsert(UserProfile profile) async {
    await _fs.upsert(
      _doc(profile.uid),
      profile.copyWith(updatedAt: DateTime.now()),
    );
  }

  Future<void> upsertWithUniqueUsername(UserProfile profile) async {
    final displayName = normalizeUsername(profile.displayName ?? '');
    if (displayName.isEmpty) {
      await upsert(profile);
      return;
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

        final updatedProfile = profile.copyWith(
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
    await _fs.instance
        .collection(DatabaseCollections.users)
        .doc(uid)
        .update(data);
  }

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

  Stream<UserProfile?> watchById(String uid) {
    return _fs.watchDoc(_doc(uid));
  }

  Stream<List<UserProfile>> watchAll({int? limit}) {
    return _fs.watchCol(_col(), limit: limit);
  }
}
