import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

String? buildPollGroupInviteLink(PollGroup group) {
  if (!group.inviteLinkEnabled) {
    return null;
  }

  return Uri(
    scheme: 'https',
    host: Uri.parse(Environment.shareBaseUrl).host,
    path: '/group-invite',
    queryParameters: <String, String>{'groupId': group.id},
  ).toString();
}

String formatPollGroupDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

extension PollGroupAccessModeLocalization on PollGroupAccessMode {
  String localizedTitle(BuildContext context) {
    switch (this) {
      case PollGroupAccessMode.private:
        return context.l10n.completelyPrivateAccessMode;
      case PollGroupAccessMode.protected:
        return context.l10n.protectedAccessMode;
      case PollGroupAccessMode.open:
        return context.l10n.openAccessMode;
    }
  }

  String localizedDescription(BuildContext context) {
    switch (this) {
      case PollGroupAccessMode.private:
        return context.l10n.onlyPreparedMembersCanParticipate;
      case PollGroupAccessMode.protected:
        return context.l10n.peopleWithInviteLinkCanRequestAccessToGroup;
      case PollGroupAccessMode.open:
        return context.l10n.everyoneCanJoinWithoutApproval;
    }
  }
}

class PollGroupSummaryCard extends StatelessWidget {
  const PollGroupSummaryCard({
    super.key,
    required this.group,
    required this.summary,
    this.trailing,
    this.footer,
    this.onTap,
  });

  final PollGroup group;
  final String summary;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trailingChildren = switch (trailing) {
      final widget? => <Widget>[widget],
      null => const <Widget>[],
    };
    final footerChildren = switch (footer) {
      final widget? => <Widget>[const SizedBox(height: 10), widget],
      null => const <Widget>[],
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                  ...trailingChildren,
                ],
              ),
              const SizedBox(height: 8),
              Text(summary),
              ...footerChildren,
            ],
          ),
        ),
      ),
    );
  }
}
