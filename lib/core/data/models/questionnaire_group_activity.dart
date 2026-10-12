import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionnaireGroupActivityType {
  groupCreated,
  settingsUpdated,
  invitationsSent,
  memberJoined,
  memberLeft,
  memberRemoved,
  ownershipTransferred,
  adminElectionStarted,
  adminElectionCompleted,
  publicationPublished,
  unknown,
}

String questionnaireGroupActivityTypeToFirestore(
  QuestionnaireGroupActivityType type,
) => switch (type) {
  QuestionnaireGroupActivityType.groupCreated => 'group_created',
  QuestionnaireGroupActivityType.settingsUpdated => 'settings_updated',
  QuestionnaireGroupActivityType.invitationsSent => 'invitations_sent',
  QuestionnaireGroupActivityType.memberJoined => 'member_joined',
  QuestionnaireGroupActivityType.memberLeft => 'member_left',
  QuestionnaireGroupActivityType.memberRemoved => 'member_removed',
  QuestionnaireGroupActivityType.ownershipTransferred =>
    'ownership_transferred',
  QuestionnaireGroupActivityType.adminElectionStarted =>
    'admin_election_started',
  QuestionnaireGroupActivityType.adminElectionCompleted =>
    'admin_election_completed',
  QuestionnaireGroupActivityType.publicationPublished =>
    'publication_published',
  QuestionnaireGroupActivityType.unknown => 'unknown',
};

QuestionnaireGroupActivityType parseQuestionnaireGroupActivityType(
  String? value,
) => switch (value) {
  'group_created' => QuestionnaireGroupActivityType.groupCreated,
  'settings_updated' => QuestionnaireGroupActivityType.settingsUpdated,
  'invitations_sent' => QuestionnaireGroupActivityType.invitationsSent,
  'member_joined' => QuestionnaireGroupActivityType.memberJoined,
  'member_left' => QuestionnaireGroupActivityType.memberLeft,
  'member_removed' => QuestionnaireGroupActivityType.memberRemoved,
  'ownership_transferred' =>
    QuestionnaireGroupActivityType.ownershipTransferred,
  'admin_election_started' =>
    QuestionnaireGroupActivityType.adminElectionStarted,
  'admin_election_completed' =>
    QuestionnaireGroupActivityType.adminElectionCompleted,
  'publication_published' =>
    QuestionnaireGroupActivityType.publicationPublished,
  _ => QuestionnaireGroupActivityType.unknown,
};

class QuestionnaireGroupActivity {
  const QuestionnaireGroupActivity({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.createdAt,
    this.actorDisplayName,
    this.subjectUid,
    this.subjectDisplayName,
    this.targetTitle,
    this.count,
  });

  final String id;
  final QuestionnaireGroupActivityType type;
  final String actorUid;
  final String? actorDisplayName;
  final String? subjectUid;
  final String? subjectDisplayName;
  final String? targetTitle;
  final int? count;
  final DateTime createdAt;

  static QuestionnaireGroupActivity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return QuestionnaireGroupActivity(
      id: snapshot.id,
      type: parseQuestionnaireGroupActivityType(data['type'] as String?),
      actorUid: data['actorUid'] as String? ?? '',
      actorDisplayName: data['actorDisplayName'] as String?,
      subjectUid: data['subjectUid'] as String?,
      subjectDisplayName: data['subjectDisplayName'] as String?,
      targetTitle: data['targetTitle'] as String?,
      count: data['count'] as int?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static Map<String, Object?> toFirestore(
    QuestionnaireGroupActivity activity,
    SetOptions? _,
  ) {
    return {
      'type': questionnaireGroupActivityTypeToFirestore(activity.type),
      'actorUid': activity.actorUid,
      'actorDisplayName': activity.actorDisplayName,
      'subjectUid': activity.subjectUid,
      'subjectDisplayName': activity.subjectDisplayName,
      'targetTitle': activity.targetTitle,
      'count': activity.count,
      'createdAt': Timestamp.fromDate(activity.createdAt),
    };
  }
}
