import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/groups/group_entry_page.dart';
import 'package:stimmapp/core/data/models/questionnaire_group.dart';

void main() {
  final group = QuestionnaireGroup(
    id: 'group-1',
    name: 'Open group',
    createdBy: 'owner',
    createdAt: DateTime(2026, 1, 1),
    joinCode: 'OPEN-1',
    nicknameMode: QuestionnaireGroupNicknameMode.selfNamed,
    managersCanInvite: true,
    memberIds: const ['owner'],
    importedMemberCount: 1,
    accessMode: QuestionnaireGroupAccessMode.open,
    inviteLinkEnabled: true,
  );

  test('pending invitation prevents automatic open-group membership', () {
    final invitation = QuestionnaireGroupAccessNotification(
      id: 'invite-1',
      groupId: group.id,
      groupName: group.name,
      actorUid: 'owner',
      actorDisplayName: 'Owner',
      recipientUid: 'invitee',
      role: QuestionnaireGroupRole.user,
      accessMode: QuestionnaireGroupAccessMode.open,
      type: QuestionnaireGroupAccessNotificationType.invite,
      status: QuestionnaireGroupAccessNotificationStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    );

    expect(
      shouldAutoJoinOpenGroup(
        group: group,
        notification: invitation,
        currentUid: 'invitee',
        isSaving: false,
        attemptedForUid: null,
      ),
      isFalse,
    );
  });

  test('open invite link without invitation can still auto-join', () {
    expect(
      shouldAutoJoinOpenGroup(
        group: group,
        notification: null,
        currentUid: 'visitor',
        isSaving: false,
        attemptedForUid: null,
      ),
      isTrue,
    );
  });
}
