import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/services/file_output/group_activity_export.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/poll_group_activity.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:trainvent_general/trainvent_general.dart';

class GroupActivityPage extends StatefulWidget {
  const GroupActivityPage({
    super.key,
    required this.group,
    this.repository,
    this.auth,
  });

  final PollGroup group;
  final PollGroupRepository? repository;
  final AuthService? auth;

  @override
  State<GroupActivityPage> createState() => _GroupActivityPageState();
}

class _GroupActivityPageState extends State<GroupActivityPage> {
  late final Stream<List<PollGroupActivity>> _activities = _repository
      .watchActivities(widget.group.id);
  bool _exporting = false;

  Future<void> _download(List<PollGroupActivity> activities) async {
    setState(() => _exporting = true);
    try {
      final (group, members) = await (
        _repository.getGroup(widget.group.id),
        _repository.watchMembers(widget.group.id).first,
      ).wait;
      if (!mounted) return;
      if (group == null) throw StateError('Group no longer exists');
      final now = DateTime.now().toUtc();
      final groupId = widget.group.id.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      await FilePicker.saveFile(
        dialogTitle: context.l10n.exportJson,
        fileName:
            'group_${groupId}_info_${DateFormat('yyyyMMdd_HHmmss').format(now)}.json',
        mimeType: 'application/json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(
          utf8.encode(
            buildGroupActivityExport(
              group,
              activities,
              exportedAt: now,
              members: members,
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) showErrorSnackBar(context.l10n.exportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  PollGroupRepository get _repository =>
      widget.repository ?? PollGroupRepository.create();
  AuthService get _auth => widget.auth ?? authService;

  IconData _icon(PollGroupActivityType type) => switch (type) {
    PollGroupActivityType.groupCreated => Icons.group_add_outlined,
    PollGroupActivityType.settingsUpdated => Icons.tune_outlined,
    PollGroupActivityType.invitationsSent => Icons.mark_email_unread_outlined,
    PollGroupActivityType.memberJoined => Icons.person_add_alt_outlined,
    PollGroupActivityType.memberLeft => Icons.person_remove_outlined,
    PollGroupActivityType.memberRemoved => Icons.person_off_outlined,
    PollGroupActivityType.ownershipTransferred => Icons.swap_horiz_outlined,
    PollGroupActivityType.adminElectionStarted ||
    PollGroupActivityType.adminElectionCompleted => Icons.how_to_vote_outlined,
    PollGroupActivityType.publicationPublished => Icons.campaign_outlined,
    PollGroupActivityType.unknown => Icons.history_outlined,
  };

  String _actor(BuildContext context, PollGroupActivity activity) {
    final name = activity.actorDisplayName?.trim();
    return name == null || name.isEmpty
        ? context.l10n.groupActivityActorFallback
        : name;
  }

  String _subject(BuildContext context, PollGroupActivity activity) {
    final name = activity.subjectDisplayName?.trim();
    return name == null || name.isEmpty
        ? context.l10n.groupActivitySubjectFallback
        : name;
  }

  String _message(BuildContext context, PollGroupActivity activity) {
    final actor = _actor(context, activity);
    final subject = _subject(context, activity);
    return switch (activity.type) {
      PollGroupActivityType.groupCreated => context.l10n.groupActivityCreated(
        actor,
      ),
      PollGroupActivityType.settingsUpdated =>
        context.l10n.groupActivitySettingsUpdated(actor),
      PollGroupActivityType.invitationsSent =>
        context.l10n.groupActivityInvitationsSent(actor, activity.count ?? 0),
      PollGroupActivityType.memberJoined =>
        context.l10n.groupActivityMemberJoined(actor),
      PollGroupActivityType.memberLeft => context.l10n.groupActivityMemberLeft(
        actor,
      ),
      PollGroupActivityType.memberRemoved =>
        context.l10n.groupActivityMemberRemoved(actor, subject),
      PollGroupActivityType.ownershipTransferred =>
        context.l10n.groupActivityOwnershipTransferred(actor, subject),
      PollGroupActivityType.adminElectionStarted =>
        context.l10n.groupActivityAdminElectionStarted(actor),
      PollGroupActivityType.adminElectionCompleted =>
        context.l10n.groupActivityAdminElectionCompleted(subject),
      PollGroupActivityType.publicationPublished =>
        context.l10n.groupActivityPublicationPublished(
          actor,
          activity.targetTitle ?? context.l10n.untitled,
        ),
      PollGroupActivityType.unknown => context.l10n.groupActivityUpdated,
    };
  }

  String _formattedDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).add_Hm().format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.groupActivityTitle)),
        body: Center(child: Text(context.l10n.pleaseSignInToViewYourGroups)),
      );
    }
    return StreamBuilder<List<PollGroupActivity>>(
      stream: _activities,
      builder: (context, snapshot) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.groupActivityTitle),
          actions: [
            IconButton(
              tooltip: context.l10n.groupInfoDownload,
              onPressed: _exporting || snapshot.hasError || !snapshot.hasData
                  ? null
                  : () => _download(List.of(snapshot.data!)),
              icon: _exporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(
                        child: TriangleLoadingIndicator(showFill: false),
                      ),
                    )
                  : const Icon(Icons.file_download_outlined),
            ),
          ],
        ),
        body: _buildActivities(context, snapshot),
      ),
    );
  }

  Widget _buildActivities(
    BuildContext context,
    AsyncSnapshot<List<PollGroupActivity>> snapshot,
  ) {
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.groupActivityLoadFailed,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: TriangleLoadingIndicator(showFill: false));
    }
    final activities = snapshot.data!;
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.noGroupActivity,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activities.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          leading: CircleAvatar(child: Icon(_icon(activity.type))),
          title: Text(_message(context, activity)),
          subtitle: Text(_formattedDate(context, activity.createdAt)),
        );
      },
    );
  }
}
