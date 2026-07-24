import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/groups/group_entry_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';

void main() {
  final group = PollGroup(
    id: 'group-1',
    name: 'Open group',
    createdBy: 'owner',
    createdAt: DateTime(2026, 1, 1),
    joinCode: 'OPEN-1',
    nicknameMode: PollGroupNicknameMode.selfNamed,
    managersCanInvite: true,
    memberIds: const ['owner'],
    importedMemberCount: 1,
    accessMode: PollGroupAccessMode.open,
    inviteLinkEnabled: true,
  );

  test('pending invitation prevents automatic open-group membership', () {
    final invitation = PollGroupAccessNotification(
      id: 'invite-1',
      groupId: group.id,
      groupName: group.name,
      actorUid: 'owner',
      actorDisplayName: 'Owner',
      recipientUid: 'invitee',
      role: PollGroupRole.user,
      accessMode: PollGroupAccessMode.open,
      type: PollGroupAccessNotificationType.invite,
      status: PollGroupAccessNotificationStatus.pending,
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
