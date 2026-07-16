import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
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

  Future<void> _removeMember(
    PollGroupMember member,
    UserProfile? profile,
  ) async {
    final currentUid = _auth.currentUser?.uid;
    if (member.uid == widget.group.createdBy) {
      showErrorSnackBar(context.l10n.cannotRemoveGroupCreator);
      return;
    }
    if (member.uid == currentUid) {
      showErrorSnackBar(context.l10n.youCannotRemoveYourselfHere);
      return;
    }

    final memberName = profile?.displayName?.trim().isNotEmpty == true
        ? profile!.displayName!.trim()
        : (profile?.email?.trim().isNotEmpty == true
              ? profile!.email!.trim()
              : context.l10n.unknownGroupMember);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removeGroupMemberTitle),
        content: Text(context.l10n.removeGroupMemberConfirmation(memberName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _removingMemberIds.add(member.uid));
    try {
      await _repository.removeMember(
        group: widget.group,
        uid: member.uid,
        email: profile?.email,
      );
      if (mounted) {
        showSuccessSnackBar(context.l10n.groupMemberRemoved);
      }
    } catch (error, stackTrace) {
      await showInternalDifficultiesSnackBar(error, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _removingMemberIds.remove(member.uid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.manageGroupMembersTitle)),
      body: StreamBuilder<List<PollGroupMember>>(
        stream: _repository.watchMembers(widget.group.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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
                future: _userRepository.getById(member.uid),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  final displayName = profile?.displayName?.trim();
                  final email = profile?.email?.trim();
                  final title = displayName?.isNotEmpty == true
                      ? displayName!
                      : (email?.isNotEmpty == true
                            ? email!
                            : context.l10n.unknownGroupMember);
                  final isCreator = member.uid == widget.group.createdBy;
                  final isCurrentUser = member.uid == _auth.currentUser?.uid;
                  final canRemove = !isCreator && !isCurrentUser;
                  final isRemoving = _removingMemberIds.contains(member.uid);

                  return ListTile(
                    key: Key('group_member_${member.uid}'),
                    leading: CircleAvatar(
                      child: Text(title.characters.first.toUpperCase()),
                    ),
                    title: Text(title),
                    subtitle: Text(
                      [
                        if (displayName?.isNotEmpty == true &&
                            email?.isNotEmpty == true)
                          email!,
                        _roleLabel(context, member.role),
                      ].join(' · '),
                    ),
                    trailing: isCreator
                        ? Chip(label: Text(context.l10n.creatorRoleLabel))
                        : IconButton(
                            tooltip: context.l10n.removeMemberTooltip,
                            onPressed: canRemove && !isRemoving
                                ? () => _removeMember(member, profile)
                                : null,
                            icon: isRemoving
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.person_remove_outlined),
                          ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
