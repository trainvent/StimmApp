import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/app_limits.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GroupMembersPage extends StatefulWidget {
  const GroupMembersPage({
    super.key,
    required this.group,
    this.repository,
    this.userRepository,
    this.auth,
  });

  final PollGroup group;
  final PollGroupRepository? repository;
  final UserRepository? userRepository;
  final AuthService? auth;

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final Set<String> _removingMemberIds = <String>{};
  final Set<String> _updatingMemberIds = <String>{};
  final Map<String, Future<UserProfile?>> _profileFutures = {};
  final Map<String, ({PollGroupMember member, UserProfile? profile})>
  _selectedMembers = {};

  bool get _selectionMode => _selectedMembers.isNotEmpty;

  PollGroupRepository get _repository =>
      widget.repository ?? PollGroupRepository.create();
  UserRepository get _userRepository =>
      widget.userRepository ?? UserRepository.create();
  AuthService get _auth => widget.auth ?? authService;

  String _roleLabel(BuildContext context, PollGroupRole role) {
    return switch (role) {
      PollGroupRole.admin => context.l10n.adminRoleLabel,
      PollGroupRole.manager => context.l10n.managerRoleLabel,
      PollGroupRole.user => context.l10n.userRoleLabel,
    };
  }

  String _memberName(PollGroupMember member, UserProfile? profile) {
    final nickname = member.nickname?.trim();
    if (nickname?.isNotEmpty == true) {
      return nickname!;
    }
    final displayName = profile?.displayName?.trim();
    if (displayName?.isNotEmpty == true) {
      return displayName!;
    }
    final email = profile?.email?.trim();
    return email?.isNotEmpty == true ? email! : context.l10n.unknownGroupMember;
  }

  void _toggleMemberSelection(PollGroupMember member, UserProfile? profile) {
    setState(() {
      if (_selectedMembers.containsKey(member.uid)) {
        _selectedMembers.remove(member.uid);
      } else {
        _selectedMembers[member.uid] = (member: member, profile: profile);
      }
    });
  }

  void _handleMemberLongPress(PollGroupMember member, UserProfile? profile) {
    final currentUid = _auth.currentUser?.uid;
    if (member.uid == widget.group.createdBy) {
      showErrorSnackBar(context.l10n.cannotRemoveGroupOwner);
      return;
    }
    if (member.uid == currentUid) {
      showErrorSnackBar(context.l10n.youCannotRemoveYourselfHere);
      return;
    }
    _toggleMemberSelection(member, profile);
  }

  Future<void> _removeSelectedMembers() async {
    final selected = _selectedMembers.values.toList();
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removeSelectedGroupMembersTitle),
        content: Text(
          context.l10n.removeSelectedGroupMembersConfirmation(selected.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const Key('confirm_remove_selected_members'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) {
      showErrorSnackBar(context.l10n.pleaseSignInFirst);
      return;
    }

    final memberIds = selected.map((entry) => entry.member.uid).toSet();
    setState(() {
      _selectedMembers.clear();
      _removingMemberIds.addAll(memberIds);
    });
    final actorNameFallback = context.l10n.groupAdminFallback;
    try {
      final actorProfile = await _userRepository.getById(currentUid);
      final actorDisplayName =
          actorProfile?.displayName?.trim().isNotEmpty == true
          ? actorProfile!.displayName!.trim()
          : (actorProfile?.email?.trim().isNotEmpty == true
                ? actorProfile!.email!.trim()
                : actorNameFallback);
      for (final entry in selected) {
        await _repository.removeMember(
          group: widget.group,
          uid: entry.member.uid,
          actorUid: currentUid,
          actorDisplayName: actorDisplayName,
          role: entry.member.role,
          email: entry.profile?.email,
          memberDisplayName: _memberName(entry.member, entry.profile),
        );
      }
      if (mounted) {
        showSuccessSnackBar(
          context.l10n.selectedGroupMembersRemoved(selected.length),
        );
      }
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _removingMemberIds.removeAll(memberIds));
      }
    }
  }

  Future<void> _editMember(PollGroupMember member, UserProfile? profile) async {
    var nickname = member.nickname ?? '';
    var selectedRole = member.role;
    final isCreator = member.uid == widget.group.createdBy;
    final result = await showDialog<({String nickname, PollGroupRole role})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.editGroupMemberTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('group_member_nickname_field'),
                initialValue: nickname,
                autofocus: true,
                maxLength: AppLimits.maxGroupNicknameLength,
                decoration: InputDecoration(labelText: context.l10n.nickname),
                onChanged: (value) => nickname = value,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PollGroupRole>(
                key: const Key('group_member_role_field'),
                initialValue: selectedRole,
                decoration: InputDecoration(labelText: context.l10n.roleLabel),
                items: PollGroupRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(context, role)),
                      ),
                    )
                    .toList(),
                onChanged: isCreator
                    ? null
                    : (role) {
                        if (role != null) {
                          setDialogState(() => selectedRole = role);
                        }
                      },
              ),
              if (isCreator)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.l10n.groupOwnerMustRemainAdmin,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              key: const Key('save_group_member'),
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop((nickname: nickname, role: selectedRole)),
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() => _updatingMemberIds.add(member.uid));
    try {
      await _repository.updateMember(
        group: widget.group,
        member: member,
        nickname: result.nickname,
        role: result.role,
        email: profile?.email,
      );
      if (mounted) {
        showSuccessSnackBar(context.l10n.groupMemberUpdated);
      }
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _updatingMemberIds.remove(member.uid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) {
          setState(_selectedMembers.clear);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _selectionMode
              ? IconButton(
                  tooltip: context.l10n.cancel,
                  onPressed: () => setState(_selectedMembers.clear),
                  icon: const Icon(Icons.close),
                )
              : null,
          title: Text(
            _selectionMode
                ? context.l10n.selectedGroupMembersCount(
                    _selectedMembers.length,
                  )
                : context.l10n.manageGroupMembersTitle,
          ),
          actions: [
            if (_selectionMode)
              IconButton(
                key: const Key('remove_selected_group_members'),
                tooltip: context.l10n.remove,
                onPressed: _removeSelectedMembers,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: StreamBuilder<List<PollGroupMember>>(
          stream: _repository.watchMembers(widget.group.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(
                child: TriangleLoadingIndicator(showFill: false),
              );
            }
            final members = snapshot.data!;
            if (members.isEmpty) {
              return Center(child: Text(context.l10n.noGroupMembers));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                    child: Text(
                      context.l10n.manageGroupMembersDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final member = members[index - 1];
                return FutureBuilder<UserProfile?>(
                  future: _profileFutures.putIfAbsent(
                    member.uid,
                    () => _userRepository.getById(member.uid),
                  ),
                  builder: (context, profileSnapshot) {
                    final profile = profileSnapshot.data;
                    final displayName = profile?.displayName?.trim();
                    final email = profile?.email?.trim();
                    final nickname = member.nickname?.trim();
                    final title = nickname?.isNotEmpty == true
                        ? nickname!
                        : displayName?.isNotEmpty == true
                        ? displayName!
                        : (email?.isNotEmpty == true
                              ? email!
                              : context.l10n.unknownGroupMember);
                    final isCreator = member.uid == widget.group.createdBy;
                    final isCurrentUser = member.uid == _auth.currentUser?.uid;
                    final canRemove = !isCreator && !isCurrentUser;
                    final isRemoving = _removingMemberIds.contains(member.uid);
                    final isUpdating = _updatingMemberIds.contains(member.uid);
                    final isBusy = isRemoving || isUpdating;
                    final isSelected = _selectedMembers.containsKey(member.uid);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: isBusy
                          ? null
                          : () => _handleMemberLongPress(member, profile),
                      child: ListTile(
                        key: Key('group_member_${member.uid}'),
                        selected: isSelected,
                        leading: _selectionMode && canRemove
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) =>
                                    _toggleMemberSelection(member, profile),
                              )
                            : CircleAvatar(
                                child: Text(
                                  title.characters.first.toUpperCase(),
                                ),
                              ),
                        title: Text(title),
                        subtitle: email?.isNotEmpty == true
                            ? Text(email!)
                            : null,
                        onTap: isBusy
                            ? null
                            : _selectionMode
                            ? (canRemove
                                  ? () =>
                                        _toggleMemberSelection(member, profile)
                                  : null)
                            : () => _editMember(member, profile),
                        trailing: isBusy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: TriangleLoadingIndicator(
                                  size: 20,
                                  strokeWidth: 2,
                                  showFill: false,
                                ),
                              )
                            : Chip(
                                label: Text(
                                  isCreator
                                      ? context.l10n.ownerRoleLabel
                                      : _roleLabel(context, member.role),
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
