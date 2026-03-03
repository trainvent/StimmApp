import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/moderation_report.dart';
import 'package:stimmapp/core/data/services/database_service.dart';

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

  Stream<Set<String>> watchBlockedUserIds(String userId) {
    return _blockedUsers(
      userId,
    ).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Stream<List<ModerationReport>> watchOpenReports({int limit = 100}) {
    return _fs.watchCol(
      _reports()
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true),
      limit: limit,
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
    await _reports().add(
      ModerationReport(
        id: '',
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        contentType: contentType,
        contentId: contentId,
        reason: reason,
        details: details?.trim().isEmpty ?? true ? null : details?.trim(),
        source: source,
      ),
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
    final reportRef = _fs.instance
        .collection(DatabaseCollections.moderationReports)
        .doc();
    batch.set(_blockedUsers(blockerId).doc(blockedUserId), <String, Object?>{
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedUserId': blockedUserId,
      'contentType': contentType,
      'contentId': contentId,
    });
    batch.set(reportRef, <String, Object?>{
      'reporterId': blockerId,
      'reportedUserId': blockedUserId,
      'contentType': contentType,
      'contentId': contentId,
      'reason': 'blocked_user',
      'details': details?.trim().isEmpty ?? true ? null : details?.trim(),
      'source': 'block',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> resolveReport(String reportId) async {
    await _reports().doc(reportId).update(<String, Object?>{
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
