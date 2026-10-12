import 'package:flutter/material.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/models/questionnaire_group.dart';
import 'package:stimmapp/core/data/repositories/questionnaire_group_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GroupInvitationsPage extends StatelessWidget {
  const GroupInvitationsPage({super.key, required this.group, this.repository});

  final QuestionnaireGroup group;
  final QuestionnaireGroupRepository? repository;

  QuestionnaireGroupRepository get _repository =>
      repository ?? QuestionnaireGroupRepository.create();

  String _statusLabel(
    BuildContext context,
    QuestionnaireGroupInvitationStatus status,
  ) {
    return switch (status) {
      QuestionnaireGroupInvitationStatus.pending =>
        context.l10n.invitationStatusPending,
      QuestionnaireGroupInvitationStatus.accepted =>
        context.l10n.invitationStatusAccepted,
      QuestionnaireGroupInvitationStatus.declined =>
        context.l10n.invitationStatusDeclined,
      QuestionnaireGroupInvitationStatus.removed =>
        context.l10n.invitationStatusRemoved,
    };
  }

  IconData _statusIcon(QuestionnaireGroupInvitationStatus status) {
    return switch (status) {
      QuestionnaireGroupInvitationStatus.pending => Icons.schedule_outlined,
      QuestionnaireGroupInvitationStatus.accepted => Icons.check_circle_outline,
      QuestionnaireGroupInvitationStatus.declined => Icons.cancel_outlined,
      QuestionnaireGroupInvitationStatus.removed =>
        Icons.person_remove_outlined,
    };
  }

  Color _statusColor(
    BuildContext context,
    QuestionnaireGroupInvitationStatus status,
  ) {
    return switch (status) {
      QuestionnaireGroupInvitationStatus.pending => Colors.orange,
      QuestionnaireGroupInvitationStatus.accepted => Colors.green,
      QuestionnaireGroupInvitationStatus.declined => Theme.of(
        context,
      ).colorScheme.error,
      QuestionnaireGroupInvitationStatus.removed => Theme.of(
        context,
      ).colorScheme.onSurfaceVariant,
    };
  }

  String _roleLabel(BuildContext context, QuestionnaireGroupRole role) {
    return switch (role) {
      QuestionnaireGroupRole.admin => context.l10n.adminRoleLabel,
      QuestionnaireGroupRole.manager => context.l10n.managerRoleLabel,
      QuestionnaireGroupRole.user => context.l10n.memberRoleLabel,
    };
  }

  String _dateLabel(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatShortDate(local)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupInvitationsTitle)),
      body: StreamBuilder<List<QuestionnaireGroupInvitation>>(
        stream: _repository.watchInvitations(group.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: TriangleLoadingIndicator(showFill: false),
            );
          }
          final invitations = snapshot.data!;
          if (invitations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.noGroupInvitations,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                  child: Text(context.l10n.groupInvitationsDescription),
                );
              }
              final invitation = invitations[index - 1];
              final name = invitation.displayName?.trim();
              final title = name?.isNotEmpty == true ? name! : invitation.email;
              final statusColor = _statusColor(context, invitation.status);

              return ListTile(
                key: Key('group_invitation_${invitation.recipientUid}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: CircleAvatar(
                  child: Icon(_statusIcon(invitation.status)),
                ),
                title: Text(title),
                subtitle: Text(
                  [
                    if (name?.isNotEmpty == true) invitation.email,
                    _roleLabel(context, invitation.role),
                    _dateLabel(context, invitation.invitedAt),
                  ].join(' · '),
                ),
                trailing: Chip(
                  avatar: Icon(
                    _statusIcon(invitation.status),
                    color: statusColor,
                    size: 18,
                  ),
                  label: Text(_statusLabel(context, invitation.status)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
