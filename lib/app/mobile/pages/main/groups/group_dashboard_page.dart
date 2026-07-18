import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_admin_election_page.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_editor_page.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_invitations_page.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_members_page.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_ui.dart';
import 'package:stimmapp/app/mobile/pages/main/home/polls/polls_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GroupDashboardPage extends StatelessWidget {
  const GroupDashboardPage({
    super.key,
    required this.group,
    this.repository,
    this.auth,
  });

  final PollGroup group;
  final PollGroupRepository? repository;
  final AuthService? auth;

  PollGroupRepository get _repository =>
      repository ?? PollGroupRepository.create();
  AuthService get _auth => auth ?? authService;

  String _roleLabel(BuildContext context, PollGroupRole? role, bool isCreator) {
    if (isCreator) {
      return context.l10n.creatorRoleLabel;
    }
    return switch (role) {
      PollGroupRole.admin => context.l10n.adminRoleLabel,
      PollGroupRole.manager => context.l10n.managerRoleLabel,
      PollGroupRole.user || null => context.l10n.memberRoleLabel,
    };
  }

  Future<void> _copyInviteLink(BuildContext context, PollGroup group) async {
    final link = buildPollGroupInviteLink(group);
    if (link == null) {
      showErrorSnackBar(context.l10n.groupHasNoActiveInviteLink);
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      showSuccessSnackBar(context.l10n.linkCopiedToClipboard);
    }
  }

  Future<void> _deleteGroup(BuildContext context, PollGroup group) async {
    var enteredGroupName = '';
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final nameMatches = enteredGroupName.trim() == group.name.trim();
            return AlertDialog(
              title: Text(context.l10n.deleteGroup),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.typeGroupNameToConfirmDeletion(group.name)),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (value) =>
                        setDialogState(() => enteredGroupName = value),
                    decoration: InputDecoration(
                      labelText: context.l10n.groupNameLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.l10n.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: nameMatches
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(context.l10n.deleteGroup),
                ),
              ],
            );
          },
        ),
      );
      if (confirmed != true || !context.mounted) {
        return;
      }

      await _repository.deleteGroup(group.id);
      if (!context.mounted) {
        return;
      }
      showSuccessSnackBar(context.l10n.groupDeleted);
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    }
  }

  Future<void> _open(Widget page, BuildContext context) {
    return Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => page));
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.pleaseSignInToViewYourGroups)),
      );
    }

    return StreamBuilder<PollGroup?>(
      stream: _repository.watchGroup(group.id),
      initialData: group,
      builder: (context, groupSnapshot) {
        final currentGroup = groupSnapshot.data;
        if (currentGroup == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(context.l10n.notFound)),
          );
        }
        return StreamBuilder<PollGroupMember?>(
          stream: _repository.watchMember(currentGroup.id, uid),
          builder: (context, memberSnapshot) {
            final member = memberSnapshot.data;
            final isCreator = currentGroup.createdBy == uid;
            final canManage = isCreator || member?.role == PollGroupRole.admin;
            final roleLabel = _roleLabel(context, member?.role, isCreator);
            final expiresAt = currentGroup.expiresAt;
            final expiryLabel = expiresAt == null
                ? context.l10n.noExpiry
                : context.l10n.expiresOnDate(formatPollGroupDate(expiresAt));

            return Scaffold(
              appBar: AppBar(title: Text(currentGroup.name)),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.groups_2_outlined, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  currentGroup.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                              Chip(label: Text(roleLabel)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                  Icons.people_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  context.l10n.activeMembersCount(
                                    currentGroup.memberIds.length,
                                  ),
                                ),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  currentGroup.accessMode.localizedTitle(
                                    context,
                                  ),
                                ),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.event_outlined,
                                  size: 18,
                                ),
                                label: Text(expiryLabel),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (currentGroup.adminElectionOpen &&
                      currentGroup.adminElectionEndsAt != null) ...[
                    Text(
                      context.l10n.adminElectionTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    _actionCard(
                      context: context,
                      icon: Icons.how_to_vote_outlined,
                      title: context.l10n.voteForNewGroupAdmin,
                      description:
                          context.l10n.adminElectionDashboardDescription,
                      onTap: () => _open(
                        GroupAdminElectionPage(
                          group: currentGroup,
                          repository: repository,
                          auth: auth,
                        ),
                        context,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    context.l10n.groupContentTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  _actionCard(
                    context: context,
                    icon: Icons.how_to_vote_outlined,
                    title: context.l10n.viewGroupPolls,
                    description: context.l10n.viewGroupPollsDescription,
                    onTap: () => _open(
                      PollsPage(initialGroupId: currentGroup.id),
                      context,
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(height: 18),
                    Text(
                      context.l10n.groupManagementTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    _actionCard(
                      context: context,
                      icon: Icons.person_add_alt_1_outlined,
                      title: context.l10n.inviteMembersTitle,
                      description: context.l10n.inviteMembersPageDescription,
                      onTap: () => _open(
                        GroupInviteMembersPage(
                          group: currentGroup,
                          repository: repository,
                          auth: auth,
                        ),
                        context,
                      ),
                    ),
                    _actionCard(
                      context: context,
                      icon: Icons.manage_accounts_outlined,
                      title: context.l10n.manageGroupMembersTitle,
                      description: context.l10n.manageGroupMembersDescription,
                      onTap: () => _open(
                        GroupMembersPage(
                          group: currentGroup,
                          repository: repository,
                          auth: auth,
                        ),
                        context,
                      ),
                    ),
                    _actionCard(
                      context: context,
                      icon: Icons.mark_email_read_outlined,
                      title: context.l10n.groupInvitationsTitle,
                      description: context.l10n.groupInvitationsDescription,
                      onTap: () => _open(
                        GroupInvitationsPage(
                          group: currentGroup,
                          repository: repository,
                        ),
                        context,
                      ),
                    ),
                    _actionCard(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: context.l10n.editGroupTitle,
                      description: context.l10n.editGroupDescription,
                      onTap: () => _open(
                        GroupEditorPage(
                          initialGroup: currentGroup,
                          repository: repository,
                          auth: auth,
                        ),
                        context,
                      ),
                    ),
                    if (buildPollGroupInviteLink(currentGroup) != null)
                      _actionCard(
                        context: context,
                        icon: Icons.link,
                        title: context.l10n.copyInviteLinkTooltip,
                        description: context.l10n.copyInviteLinkDescription,
                        onTap: () => _copyInviteLink(context, currentGroup),
                      ),
                  ],
                  if (isCreator) ...[
                    const SizedBox(height: 18),
                    Text(
                      context.l10n.dangerZoneTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _actionCard(
                      context: context,
                      icon: Icons.delete_forever_outlined,
                      title: context.l10n.deleteGroup,
                      description: context.l10n.deleteGroupDescription,
                      onTap: () => _deleteGroup(context, currentGroup),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
