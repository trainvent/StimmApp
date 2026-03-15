import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/pages/main/home/creator/group_editor_page.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

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

  Future<void> _openEditor(
    BuildContext context, {
    PollGroup? group,
  }) async {
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

  String _accessModeTitle(PollGroupAccessMode mode) {
    switch (mode) {
      case PollGroupAccessMode.private:
        return 'Completely private';
      case PollGroupAccessMode.protected:
        return 'Protected';
      case PollGroupAccessMode.open:
        return 'Open';
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
      appBar: AppBar(title: const Text('Manage Groups')),
      body: user == null
          ? const Center(child: Text('Please sign in to manage groups.'))
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
                      'Pick an existing group to use or edit, or create a new one.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('open_group_creator_button'),
                      onPressed: () => _openEditor(context),
                      icon: const Icon(Icons.group_add),
                      label: const Text('Create new group'),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Your groups',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        groups.isEmpty)
                      const Center(child: CircularProgressIndicator()),
                    if (groups.isEmpty &&
                        snapshot.connectionState != ConnectionState.waiting)
                      const Text(
                        'No groups yet. Create one above to start team polling.',
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
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  if (selectedGroupId == group.id)
                                    const Icon(Icons.check_circle),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join code: ${group.joinCode}'
                                '${group.expiresAt != null ? ' • Expires ${_formatDate(group.expiresAt!)}' : ''}'
                                ' • Imported members: ${group.importedMemberCount}'
                                ' • ${_accessModeTitle(group.accessMode)}'
                                '${group.inviteLinkEnabled ? ' • Invite link on' : ''}',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _openEditor(context, group: group),
                                    child: const Text('Edit'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => Navigator.of(context).pop(group),
                                    child: Text(
                                      selectedGroupId == group.id
                                          ? 'Keep selected'
                                          : 'Use for this poll',
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
