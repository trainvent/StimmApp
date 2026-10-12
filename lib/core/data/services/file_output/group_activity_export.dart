import 'dart:convert';

import 'package:stimmapp/core/data/models/questionnaire_group.dart';
import 'package:stimmapp/core/data/models/questionnaire_group_activity.dart';

String buildGroupActivityExport(
  QuestionnaireGroup group,
  List<QuestionnaireGroupActivity> activities, {
  required DateTime exportedAt,
  required List<QuestionnaireGroupMember> members,
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
      'nicknameMode': questionnaireGroupNicknameModeToFirestore(
        group.nicknameMode,
      ),
      'managersCanInvite': group.managersCanInvite,
      'memberIds': group.memberIds,
      'importedMemberCount': group.importedMemberCount,
      'isActive': group.isActive,
      'accessMode': questionnaireGroupAccessModeToFirestore(group.accessMode),
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
            'role': questionnaireGroupRoleToFirestore(member.role),
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
            'type': questionnaireGroupActivityTypeToFirestore(activity.type),
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
