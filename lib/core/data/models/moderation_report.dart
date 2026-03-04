import 'package:cloud_firestore/cloud_firestore.dart';

class ModerationReportEntry {
  const ModerationReportEntry({
    required this.reporterId,
    required this.reason,
    required this.source,
    this.details,
    this.createdAt,
  });

  final String reporterId;
  final String reason;
  final String source;
  final String? details;
  final DateTime? createdAt;

  factory ModerationReportEntry.fromMap(Map<String, dynamic> data) {
    return ModerationReportEntry(
      reporterId: (data['reporterId'] ?? '') as String,
      reason: (data['reason'] ?? '') as String,
      source: (data['source'] ?? 'report') as String,
      details: data['details'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'reporterId': reporterId,
      'reason': reason,
      'source': source,
      'details': details,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : Timestamp.now(),
    };
  }
}

class ModerationReport {
  const ModerationReport({
    required this.id,
    required this.reportedUserId,
    required this.contentType,
    required this.contentId,
    required this.entries,
    this.status = 'open',
    this.createdAt,
  });

  final String id;
  final String reportedUserId;
  final String contentType;
  final String contentId;
  final List<ModerationReportEntry> entries;
  final String status;
  final DateTime? createdAt;

  ModerationReportEntry? get latestEntry =>
      entries.isEmpty ? null : entries.last;

  String get reporterId => latestEntry?.reporterId ?? '';
  String get reason => latestEntry?.reason ?? '';
  String get source => latestEntry?.source ?? 'report';
  String? get details => latestEntry?.details;

  List<String> get allReasons =>
      entries.map((entry) => entry.reason).toSet().toList();

  factory ModerationReport.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? <String, dynamic>{};
    final rawEntries = (data['entries'] as List?)
        ?.map((entry) => ModerationReportEntry.fromMap(
              Map<String, dynamic>.from(entry as Map),
            ))
        .toList();
    final fallbackEntry = ModerationReportEntry(
      reporterId: (data['reporterId'] ?? '') as String,
      reason: (data['reason'] ?? '') as String,
      source: (data['source'] ?? 'report') as String,
      details: data['details'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );

    return ModerationReport(
      id: snap.id,
      reportedUserId: (data['reportedUserId'] ?? '') as String,
      contentType: (data['contentType'] ?? '') as String,
      contentId: (data['contentId'] ?? '') as String,
      entries: rawEntries == null || rawEntries.isEmpty
          ? <ModerationReportEntry>[fallbackEntry]
          : rawEntries,
      status: (data['status'] ?? 'open') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, Object?> toFirestore(
    ModerationReport report,
    SetOptions? _,
  ) {
    final latest = report.latestEntry;
    return <String, Object?>{
      'reportedUserId': report.reportedUserId,
      'contentType': report.contentType,
      'contentId': report.contentId,
      'entries': report.entries.map((entry) => entry.toMap()).toList(),
      'reporterId': latest?.reporterId ?? '',
      'reason': latest?.reason ?? '',
      'source': latest?.source ?? 'report',
      'details': latest?.details,
      'status': report.status,
      'createdAt': report.createdAt != null
          ? Timestamp.fromDate(report.createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
