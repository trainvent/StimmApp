import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';

class PollGroupsPage extends StatefulWidget {
  const PollGroupsPage({super.key, this.selectedGroupId});

  final String? selectedGroupId;

  @override
  State<PollGroupsPage> createState() => _PollGroupsPageState();
}

class _PollGroupsPageState extends State<PollGroupsPage> {
  final _nameController = TextEditingController();
  final _bulkMembersController = TextEditingController();
  bool _allowSelfNamedNicknames = true;
  bool _managersCanInvite = true;
  bool _hasExpiration = false;
  DateTime? _expiresAt;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bulkMembersController.dispose();
    super.dispose();
  }

  Future<void> _pickExpirationDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _expiresAt = selected;
      _hasExpiration = true;
    });
  }

  List<PollGroupAllowedMember> _parseAllowedMembers(String creatorUid) {
    final now = DateTime.now();
    final lines = _bulkMembersController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    final members = <PollGroupAllowedMember>[];
    for (final line in lines) {
      final parts = line.split(',').map((part) => part.trim()).toList();
      final email = parts.isNotEmpty ? parts[0].toLowerCase() : '';
      if (!_looksLikeEmail(email)) {
        continue;
      }
      final nickname = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
      final role = parts.length > 2 ? parsePollGroupRole(parts[2].toLowerCase()) : PollGroupRole.user;
      members.add(
        PollGroupAllowedMember(
          email: email,
          nickname: nickname,
          role: role,
          createdAt: now,
          createdBy: creatorUid,
        ),
      );
    }
    return members;
  }

  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  String _buildJoinCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return 'GRP-${now.substring(now.length - 6)}';
  }

  Future<void> _createGroup() async {
    final user = authService.currentUser;
    if (user == null) {
      showErrorSnackBar('Please sign in first.');
      return;
    }
    final groupName = _nameController.text.trim();
    if (groupName.isEmpty) {
      showErrorSnackBar('Please enter a group name.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final allowedMembers = _parseAllowedMembers(user.uid);
      final repo = PollGroupRepository.create();
      final groupId = await repo.createGroup(
        creatorUid: user.uid,
        name: groupName,
        joinCode: _buildJoinCode(),
        nicknameMode: _allowSelfNamedNicknames
            ? PollGroupNicknameMode.selfNamed
            : PollGroupNicknameMode.adminAssigned,
        managersCanInvite: _managersCanInvite,
        expiresAt: _hasExpiration ? _expiresAt : null,
        allowedMembers: allowedMembers,
      );
      final group = await repo.watchGroupsForUser(user.uid).first.then(
            (groups) => groups.firstWhere(
              (item) => item.id == groupId,
            ),
          );
      if (!mounted) {
        return;
      }
      _nameController.clear();
      _bulkMembersController.clear();
      setState(() {
        _hasExpiration = false;
        _expiresAt = null;
      });
      showSuccessSnackBar('Group created.');
      Navigator.of(context).pop(group);
    } catch (e) {
      showErrorSnackBar('Failed to create group: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _roleLabel(PollGroupRole role) {
    switch (role) {
      case PollGroupRole.admin:
        return 'admin';
      case PollGroupRole.manager:
        return 'manager';
      case PollGroupRole.user:
        return 'user';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Polling Groups')),
      body: user == null
          ? const Center(child: Text('Please sign in to manage groups.'))
          : StreamBuilder<List<PollGroup>>(
              stream: PollGroupRepository.create().watchGroupsForUser(user.uid),
              builder: (context, snapshot) {
                final groups = snapshot.data ?? const <PollGroup>[];
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Create a private polling space for teams or events.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _allowSelfNamedNicknames,
                      title: const Text('Members can choose their own nickname'),
                      onChanged: (value) {
                        setState(() => _allowSelfNamedNicknames = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _managersCanInvite,
                      title: const Text('Managers can prepare access lists'),
                      onChanged: (value) {
                        setState(() => _managersCanInvite = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _hasExpiration,
                      title: const Text('Set an expiration date'),
                      onChanged: (value) {
                        setState(() {
                          _hasExpiration = value;
                          if (!value) {
                            _expiresAt = null;
                          }
                        });
                        if (value) {
                          _pickExpirationDate();
                        }
                      },
                    ),
                    if (_hasExpiration) ...[
                      OutlinedButton.icon(
                        onPressed: _pickExpirationDate,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _expiresAt == null
                              ? 'Pick expiration date'
                              : 'Expires ${_formatDate(_expiresAt!)}',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _bulkMembersController,
                      minLines: 5,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Preload members',
                        hintText:
                            'One per line: email,nickname,role\nanna@company.com,Anna,user\nlead@company.com,Team Lead,manager',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This only prepares access. No email is sent. People still need the group link or code and must join manually.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isCreating ? null : _createGroup,
                      icon: const Icon(Icons.group_add),
                      label: Text(_isCreating ? 'Creating...' : 'Create group'),
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
                    if (groups.isEmpty && snapshot.connectionState != ConnectionState.waiting)
                      const Text('No groups yet. Create one above to start team polling.'),
                    ...groups.map(
                      (group) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.groups_2_outlined),
                          title: Text(group.name),
                          subtitle: Text(
                            'Join code: ${group.joinCode}'
                            '${group.expiresAt != null ? ' • Expires ${_formatDate(group.expiresAt!)}' : ''}'
                            ' • Imported members: ${group.importedMemberCount}',
                          ),
                          trailing: widget.selectedGroupId == group.id
                              ? const Icon(Icons.check_circle)
                              : const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pop(group),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Supported preload roles: ${_roleLabel(PollGroupRole.admin)}, ${_roleLabel(PollGroupRole.manager)}, ${_roleLabel(PollGroupRole.user)}.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
