import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationReport {
  const ModerationReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.contentType,
    required this.contentId,
    required this.reason,
    required this.source,
    this.details,
    this.status = 'open',
    this.createdAt,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final String contentType;
  final String contentId;
  final String reason;
  final String source;
  final String? details;
  final String status;
  final DateTime? createdAt;

  factory ModerationReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    return ModerationReport(
      id: snap.id,
      reporterId: (data['reporterId'] ?? '') as String,
      reportedUserId: (data['reportedUserId'] ?? '') as String,
      contentType: (data['contentType'] ?? '') as String,
      contentId: (data['contentId'] ?? '') as String,
      reason: (data['reason'] ?? '') as String,
      source: (data['source'] ?? 'report') as String,
      details: data['details'] as String?,
      status: (data['status'] ?? 'open') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, Object?> toFirestore(
    ModerationReport report,
    SetOptions? _,
  ) {
    return <String, Object?>{
      'reporterId': report.reporterId,
      'reportedUserId': report.reportedUserId,
      'contentType': report.contentType,
      'contentId': report.contentId,
      'reason': report.reason,
      'source': report.source,
      'details': report.details,
      'status': report.status,
      'createdAt': report.createdAt != null
          ? Timestamp.fromDate(report.createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
