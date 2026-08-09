import 'package:cloud_firestore/cloud_firestore.dart';

enum PollGroupActivityType {
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

String pollGroupActivityTypeToFirestore(PollGroupActivityType type) =>
    switch (type) {
      PollGroupActivityType.groupCreated => 'group_created',
      PollGroupActivityType.settingsUpdated => 'settings_updated',
      PollGroupActivityType.invitationsSent => 'invitations_sent',
      PollGroupActivityType.memberJoined => 'member_joined',
      PollGroupActivityType.memberLeft => 'member_left',
      PollGroupActivityType.memberRemoved => 'member_removed',
      PollGroupActivityType.ownershipTransferred => 'ownership_transferred',
      PollGroupActivityType.adminElectionStarted => 'admin_election_started',
      PollGroupActivityType.adminElectionCompleted =>
        'admin_election_completed',
      PollGroupActivityType.publicationPublished => 'publication_published',
      PollGroupActivityType.unknown => 'unknown',
    };

PollGroupActivityType parsePollGroupActivityType(String? value) =>
    switch (value) {
      'group_created' => PollGroupActivityType.groupCreated,
      'settings_updated' => PollGroupActivityType.settingsUpdated,
      'invitations_sent' => PollGroupActivityType.invitationsSent,
      'member_joined' => PollGroupActivityType.memberJoined,
      'member_left' => PollGroupActivityType.memberLeft,
      'member_removed' => PollGroupActivityType.memberRemoved,
      'ownership_transferred' => PollGroupActivityType.ownershipTransferred,
      'admin_election_started' => PollGroupActivityType.adminElectionStarted,
      'admin_election_completed' =>
        PollGroupActivityType.adminElectionCompleted,
      'publication_published' => PollGroupActivityType.publicationPublished,
      _ => PollGroupActivityType.unknown,
    };

class PollGroupActivity {
  const PollGroupActivity({
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
  final PollGroupActivityType type;
  final String actorUid;
  final String? actorDisplayName;
  final String? subjectUid;
  final String? subjectDisplayName;
  final String? targetTitle;
  final int? count;
  final DateTime createdAt;

  static PollGroupActivity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return PollGroupActivity(
      id: snapshot.id,
      type: parsePollGroupActivityType(data['type'] as String?),
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
    PollGroupActivity activity,
    SetOptions? _,
  ) {
    return {
      'type': pollGroupActivityTypeToFirestore(activity.type),
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
