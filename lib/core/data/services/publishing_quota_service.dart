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
      _auth = auth ?? FirebaseAuth.instance,
      _now = DateTime.now;

  @visibleForTesting
  PublishingQuotaService.forTest({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    DateTime Function()? now,
  }) : _firestore = firestore,
       _auth = auth,
       _now = now ?? DateTime.now;

  static final PublishingQuotaService instance = PublishingQuotaService._();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DateTime Function() _now;

  Future<bool> _isProUser(String uid) async {
    final snap = await _firestore
        .collection(DatabaseCollections.users)
        .doc(uid)
        .get();
    final data = snap.data() ?? const <String, dynamic>{};
    final email = data['email'] as String? ?? _auth.currentUser?.email;
    return data['isPro'] == true || UserProfile.shouldForcePro(email);
  }

  Future<int> _countCreatedToday(String collection, String uid) async {
    final now = _now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);
    final startOfTomorrow = startOfDay.add(const Duration(days: 1));
    final snapshot = await _firestore
        .collection(collection)
        .where('createdBy', isEqualTo: uid)
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThan: Timestamp.fromDate(startOfTomorrow))
        .get(const GetOptions(source: Source.server));
    return snapshot.size;
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

    final counts = await Future.wait<int>([
      _countCreatedToday(DatabaseCollections.petitions, uid),
      _countCreatedToday(DatabaseCollections.polls, uid),
      _countCreatedToday(DatabaseCollections.surveys, uid),
    ]);
    return DailyPublishingStatus(
      canCreatePetition: counts[0] < 1,
      canCreatePoll: counts[1] + counts[2] < 1,
    );
  }

  Future<void> ensureCanCreatePetition() async {
    final status = await getDailyStatus();
    if (!status.canCreatePetition) {
      throw StateError('petition_daily_limit_reached');
    }
  }

  Future<void> ensureCanCreatePoll() async {
    final status = await getDailyStatus();
    if (!status.canCreatePoll) {
      throw StateError('poll_daily_limit_reached');
    }
  }
}
