import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/poll_group_activity.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:trainvent_general/trainvent_general.dart';

class GroupActivityPage extends StatelessWidget {
  const GroupActivityPage({
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
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.groupActivityTitle)),
      body: _auth.currentUser == null
          ? Center(child: Text(context.l10n.pleaseSignInToViewYourGroups))
          : StreamBuilder<List<PollGroupActivity>>(
              stream: _repository.watchActivities(group.id),
              builder: (context, snapshot) {
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
                  return const Center(
                    child: TriangleLoadingIndicator(showFill: false),
                  );
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
                      subtitle: Text(
                        _formattedDate(context, activity.createdAt),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
