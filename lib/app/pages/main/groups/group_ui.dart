import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
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

Future<void> copyPollGroupInviteLink(
  BuildContext context,
  PollGroup group,
) async {
  final inviteLink = buildPollGroupInviteLink(group);
  if (inviteLink == null) {
    showErrorSnackBar(context.l10n.groupHasNoActiveInviteLink);
    return;
  }

  await Clipboard.setData(ClipboardData(text: inviteLink));
  if (context.mounted) {
    showSuccessSnackBar(context.l10n.linkCopiedToClipboard);
  }
}

Future<void> showPollGroupInviteQrCode(
  BuildContext context,
  PollGroup group,
) async {
  final inviteLink = buildPollGroupInviteLink(group);
  if (inviteLink == null) {
    showErrorSnackBar(context.l10n.groupHasNoActiveInviteLink);
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(group.name),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: inviteLink,
              size: 240,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            SelectableText(
              inviteLink,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.l10n.close),
        ),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: inviteLink));
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
            if (context.mounted) {
              showSuccessSnackBar(context.l10n.linkCopiedToClipboard);
            }
          },
          icon: const Icon(Icons.copy_outlined),
          label: Text(dialogContext.l10n.copyLinkLabel),
        ),
      ],
    ),
  );
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
    this.embedded = false,
  });

  final PollGroup group;
  final String summary;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool embedded;

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

    final content = InkWell(
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
    );

    return embedded ? content : Card(child: content);
  }
}
