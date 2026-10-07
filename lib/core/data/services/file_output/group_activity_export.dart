import 'dart:convert';

import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/poll_group_activity.dart';

String buildGroupActivityExport(
  PollGroup group,
  List<PollGroupActivity> activities, {
  required DateTime exportedAt,
  required List<PollGroupMember> members,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'group': {
      'id': group.id,
      'name': group.name,
      'profilePictureUrl': group.profilePictureUrl,
      'createdBy': group.createdBy,
      'createdAt': group.createdAt.toUtc().toIso8601String(),
      'expiresAt': group.expiresAt?.toUtc().toIso8601String(),
      'joinCode': group.joinCode,
      'nicknameMode': pollGroupNicknameModeToFirestore(group.nicknameMode),
      'managersCanInvite': group.managersCanInvite,
      'memberIds': group.memberIds,
      'importedMemberCount': group.importedMemberCount,
      'isActive': group.isActive,
      'accessMode': pollGroupAccessModeToFirestore(group.accessMode),
      'inviteLinkEnabled': group.inviteLinkEnabled,
      'adminElectionOpen': group.adminElectionOpen,
      'adminElectionEndsAt': group.adminElectionEndsAt
          ?.toUtc()
          .toIso8601String(),
    },
    'members': members
        .map(
          (member) => {
            'uid': member.uid,
            'role': pollGroupRoleToFirestore(member.role),
            'nickname': member.nickname,
            'joinedAt': member.joinedAt.toUtc().toIso8601String(),
            'joinedBy': member.joinedBy,
          },
        )
        .toList(),
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'activities': activities
        .map(
          (activity) => {
            'id': activity.id,
            'type': pollGroupActivityTypeToFirestore(activity.type),
            'actorUid': activity.actorUid,
            'actorDisplayName': activity.actorDisplayName,
            'subjectUid': activity.subjectUid,
            'subjectDisplayName': activity.subjectDisplayName,
            'targetTitle': activity.targetTitle,
            'count': activity.count,
            'createdAt': activity.createdAt.toUtc().toIso8601String(),
          },
        )
        .toList(),
  });
}
