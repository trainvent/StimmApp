import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/moderation_report.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

class BlockedUserProfile {
  const BlockedUserProfile({
    required this.userId,
    this.profile,
  });

  final String userId;
  final UserProfile? profile;
}

class ModerationRepository {
  ModerationRepository(this._fs);

  final DatabaseService _fs;

  static ModerationRepository create() =>
      ModerationRepository(locator.databaseService);

  CollectionReference<ModerationReport> _reports() {
    return _fs.colRef<ModerationReport>(
      DatabaseCollections.moderationReports,
      fromFirestore: ModerationReport.fromFirestore,
      toFirestore: ModerationReport.toFirestore,
    );
  }

  CollectionReference<Map<String, dynamic>> _blockedUsers(String userId) {
    return _fs.instance
        .collection(DatabaseCollections.users)
        .doc(userId)
        .collection(DatabaseCollections.blockedUsers);
  }

  Future<DocumentReference<ModerationReport>?> _findOpenReport({
    required String reportedUserId,
    required String contentType,
    required String contentId,
  }) async {
    final snapshot = await _reports()
        .where('reportedUserId', isEqualTo: reportedUserId)
        .where('contentType', isEqualTo: contentType)
        .where('contentId', isEqualTo: contentId)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.reference;
  }

  Future<void> _appendEntry({
    required String reporterId,
    required String reportedUserId,
    required String contentType,
    required String contentId,
    required String reason,
    required String source,
    String? details,
  }) async {
    final normalizedDetails =
        details?.trim().isEmpty ?? true ? null : details?.trim();
    final ref = await _findOpenReport(
      reportedUserId: reportedUserId,
      contentType: contentType,
      contentId: contentId,
    );

    final entry = ModerationReportEntry(
      reporterId: reporterId,
      reason: reason,
      source: source,
      details: normalizedDetails,
      createdAt: DateTime.now(),
    );

    if (ref == null) {
      await _reports().add(
        ModerationReport(
          id: '',
          reportedUserId: reportedUserId,
          contentType: contentType,
          contentId: contentId,
          entries: <ModerationReportEntry>[entry],
        ),
      );
      return;
    }

    await ref.update(<String, Object?>{
      'entries': FieldValue.arrayUnion(<Object?>[entry.toMap()]),
      'reporterId': reporterId,
      'reason': reason,
      'source': source,
      'details': normalizedDetails,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Set<String>> watchBlockedUserIds(String userId) {
    return _blockedUsers(
      userId,
    ).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<List<BlockedUserProfile>> watchBlockedUsers(String userId) {
    return _blockedUsers(userId).snapshots().asyncMap((snapshot) async {
      final blockedUserIds = snapshot.docs.map((doc) => doc.id).toList();
      if (blockedUserIds.isEmpty) {
        return const <BlockedUserProfile>[];
      }

      final profiles = await Future.wait(
        blockedUserIds.map((blockedUserId) => locator.databaseService
            .colRef<UserProfile>(
              DatabaseCollections.users,
              fromFirestore: (snap, _) => UserProfile.fromJson(
                snap.data() as Map<String, dynamic>,
                snap.id,
              ),
              toFirestore: (model, _) => model.toJson(),
            )
            .doc(blockedUserId)
            .get()
            .then((snap) => snap.data())),
      );

      return List<BlockedUserProfile>.generate(
        blockedUserIds.length,
        (index) => BlockedUserProfile(
          userId: blockedUserIds[index],
          profile: profiles[index],
        ),
      );
    });
  }

  Stream<List<ModerationReport>> watchOpenReports({int limit = 100}) {
    return _fs
        .watchCol(
          _reports().orderBy('createdAt', descending: true),
          limit: limit,
        )
        .map(
          (reports) => reports
              .where((report) => report.status == 'open')
              .take(limit)
              .toList(),
        );
  }

  Future<void> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String contentType,
    required String contentId,
    required String reason,
    String? details,
    String source = 'report',
  }) async {
    await _appendEntry(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      contentType: contentType,
      contentId: contentId,
      reason: reason,
      details: details,
      source: source,
    );
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String contentType,
    required String contentId,
    String? details,
  }) async {
    final batch = _fs.instance.batch();
    batch.set(_blockedUsers(blockerId).doc(blockedUserId), <String, Object?>{
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedUserId': blockedUserId,
      'contentType': contentType,
      'contentId': contentId,
    });
    await batch.commit();

    await _appendEntry(
      reporterId: blockerId,
      reportedUserId: blockedUserId,
      contentType: contentType,
      contentId: contentId,
      reason: 'blocked_user',
      details: details,
      source: 'block',
    );
  }

  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    await _blockedUsers(blockerId).doc(blockedUserId).delete();
  }

  Future<void> resolveReport(String reportId) async {
    await _reports().doc(reportId).update(<String, Object?>{
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> moderateReport({
    required String reportId,
    required String action,
    String? adminMessage,
  }) async {
    await FirebaseFunctions.instance.httpsCallable('moderateReport').call(<String, Object?>{
      'reportId': reportId,
      'action': action,
      'adminMessage': adminMessage?.trim().isEmpty ?? true ? null : adminMessage?.trim(),
    });
  }
}
