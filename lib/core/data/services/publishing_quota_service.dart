import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

class DailyPublishingStatus {
  final bool canCreatePetition;
  final bool canCreatePoll;

  const DailyPublishingStatus({
    required this.canCreatePetition,
    required this.canCreatePoll,
  });
}

class PublishingQuotaService {
  PublishingQuotaService._({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  @visibleForTesting
  PublishingQuotaService.forTest({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  static final PublishingQuotaService instance = PublishingQuotaService._();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _todayKeyUtc() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyPublishing')
        .doc(_todayKeyUtc());
  }

  Future<bool> _isProUser(String uid) async {
    final snap = await _firestore
        .collection(DatabaseCollections.users)
        .doc(uid)
        .get();
    final data = snap.data() ?? const <String, dynamic>{};
    final email = data['email'] as String? ?? _auth.currentUser?.email;
    return data['isPro'] == true || UserProfile.shouldForcePro(email);
  }

  Future<DailyPublishingStatus> getDailyStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const DailyPublishingStatus(
        canCreatePetition: false,
        canCreatePoll: false,
      );
    }
    if (await _isProUser(uid)) {
      return const DailyPublishingStatus(
        canCreatePetition: true,
        canCreatePoll: true,
      );
    }
    final snap = await _doc(uid).get();
    final data = snap.data() ?? const {};
    final petitionCount = (data['petitionCount'] ?? 0) as int;
    final pollCount = (data['pollCount'] ?? 0) as int;
    return DailyPublishingStatus(
      canCreatePetition: petitionCount < 1,
      canCreatePoll: pollCount < 1,
    );
  }

  Future<void> incrementPetition() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');
    final isPro = await _isProUser(uid);
    final ref = _doc(uid);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data();
      final count = (data?['petitionCount'] ?? 0) as int;
      if (!isPro && count >= 1) {
        throw StateError('petition_daily_limit_reached');
      }
      final newData = {
        'petitionCount': count + 1,
        'lastPetitionAt': FieldValue.serverTimestamp(),
        'pollCount': (data?['pollCount'] ?? 0),
        'lastPollAt': data?['lastPollAt'],
      };
      txn.set(ref, newData, SetOptions(merge: true));
    });
  }

  Future<void> incrementPoll() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No authenticated user');
    final isPro = await _isProUser(uid);
    final ref = _doc(uid);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data();
      final count = (data?['pollCount'] ?? 0) as int;
      if (!isPro && count >= 1) {
        throw StateError('poll_daily_limit_reached');
      }
      final newData = {
        'pollCount': count + 1,
        'lastPollAt': FieldValue.serverTimestamp(),
        'petitionCount': (data?['petitionCount'] ?? 0),
        'lastPetitionAt': data?['lastPetitionAt'],
      };
      txn.set(ref, newData, SetOptions(merge: true));
    });
  }
}
