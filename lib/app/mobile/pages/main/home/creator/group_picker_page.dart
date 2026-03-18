import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_editor_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GroupPickerPage extends StatelessWidget {
  const GroupPickerPage({
    super.key,
    this.selectedGroupId,
    this.initialGroups = const <PollGroup>[],
    this.repository,
    this.auth,
  });

  final String? selectedGroupId;
  final List<PollGroup> initialGroups;
  final PollGroupRepository? repository;
  final AuthService? auth;

  PollGroupRepository get _repository =>
      repository ?? PollGroupRepository.create();
  AuthService get _auth => auth ?? authService;

  Future<void> _openEditor(BuildContext context, {PollGroup? group}) async {
    final selectedGroup = await Navigator.of(context).push<PollGroup>(
      MaterialPageRoute(
        builder: (context) => GroupEditorPage(initialGroup: group),
      ),
    );
    if (!context.mounted || selectedGroup == null) {
      return;
    }
    Navigator.of(context).pop(selectedGroup);
  }

  String _accessModeTitle(BuildContext context, PollGroupAccessMode mode) {
    switch (mode) {
      case PollGroupAccessMode.private:
        return context.l10n.completelyPrivateAccessMode;
      case PollGroupAccessMode.protected:
        return context.l10n.protectedAccessMode;
      case PollGroupAccessMode.open:
        return context.l10n.openAccessMode;
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.manageGroupsTitle)),
      body: user == null
          ? Center(child: Text(context.l10n.pleaseSignInToManageGroups))
          : StreamBuilder<List<PollGroup>>(
              stream: _repository.watchGroupsForUser(user.uid),
              builder: (context, snapshot) {
                final groupsById = <String, PollGroup>{
                  for (final group in initialGroups) group.id: group,
                  for (final group in snapshot.data ?? const <PollGroup>[])
                    group.id: group,
                };
                final groups = groupsById.values.toList();
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      context.l10n.pickExistingGroupToUseOrEditOrCreateNewOne,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('open_group_creator_button'),
                      onPressed: () => _openEditor(context),
                      icon: const Icon(Icons.group_add),
                      label: Text(context.l10n.createNewGroup),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      context.l10n.yourGroupsTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        groups.isEmpty)
                      const Center(child: CircularProgressIndicator()),
                    if (groups.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting)
                      Text(
                        context
                            .l10n
                            .noGroupsYetCreateOneAboveToStartTeamPolling,
                      ),
                    ...groups.map(
                      (group) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.groups_2_outlined),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      group.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  if (selectedGroupId == group.id)
                                    const Icon(Icons.check_circle),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                [
                                  context.l10n.joinCodeWithValue(
                                    group.joinCode,
                                  ),
                                  if (group.expiresAt != null)
                                    context.l10n.expiresOnShort(
                                      _formatDate(group.expiresAt!),
                                    ),
                                  context.l10n.importedMembersCount(
                                    group.importedMemberCount,
                                  ),
                                  _accessModeTitle(context, group.accessMode),
                                  if (group.inviteLinkEnabled)
                                    context.l10n.inviteLinkOnLabel,
                                ].join(' • '),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  OutlinedButton(
                                    onPressed: () =>
                                        _openEditor(context, group: group),
                                    child: Text(context.l10n.editLabel),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () =>
                                        Navigator.of(context).pop(group),
                                    child: Text(
                                      selectedGroupId == group.id
                                          ? context.l10n.keepSelected
                                          : context.l10n.useForThisPoll,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
