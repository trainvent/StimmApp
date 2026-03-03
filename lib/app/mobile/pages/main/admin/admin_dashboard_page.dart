import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/moderation_report.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/generated/l10n.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.adminDashboard),
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Reports'),
              Tab(text: context.l10n.users),
              Tab(text: context.l10n.polls),
              Tab(text: context.l10n.petitions),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ModerationReportsTab(),
            UserListTab(),
            PollListTab(),
            PetitionListTab(),
          ],
        ),
      ),
    );
  }
}

class ModerationReportsTab extends StatelessWidget {
  const ModerationReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ModerationRepository.create();
    return StreamBuilder<List<ModerationReport>>(
      stream: repo.watchOpenReports(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Reports failed to load: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return const Center(child: Text('No open reports.'));
        }
        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return ListTile(
              title: Text('${report.contentType} • ${report.reason}'),
              subtitle: Text(
                'Reported user: ${report.reportedUserId}\n'
                'Content: ${report.contentId}\n'
                '${report.details ?? 'No additional details.'}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () async {
                  await repo.resolveReport(report.id);
                  if (context.mounted) {
                    showSuccessSnackBar('Report marked as resolved.');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class UserListTab extends StatelessWidget {
  const UserListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = UserRepository.create();
    return StreamBuilder<List<UserProfile>>(
      stream: repo.watchAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final users = snapshot.data!;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.displayName ?? S.of(context).noName),
              subtitle: Text(user.email ?? S.of(context).noEmail),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteUser(context, user),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteUser),
        content: Text(context.l10n.areYouSureYouWantToDeleteThisUser),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFunctions.instance
                    .httpsCallable('deleteUserByAdmin')
                    .call({'uid': user.uid});
                if (context.mounted) showSuccessSnackBar(context.l10n.deleted);
              } catch (e) {
                if (context.mounted) showErrorSnackBar(e.toString());
              }
            },
            child: Text(
              context.l10n.deletePermanently,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class PollListTab extends StatelessWidget {
  const PollListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PollRepository.create();
    return StreamBuilder<List<Poll>>(
      stream: repo.list(status: IConst.active),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final polls = snapshot.data!;
        return ListView.builder(
          itemCount: polls.length,
          itemBuilder: (context, index) {
            final poll = polls[index];
            return ListTile(
              title: Text(poll.title),
              subtitle: Text(poll.status),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeletePoll(context, poll),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePoll(BuildContext context, Poll poll) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deletePoll),
        content: Text(context.l10n.areYouSureYouWantToDeleteThisPoll),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PollRepository.create().delete(poll.id);
              if (context.mounted) showSuccessSnackBar(context.l10n.deleted);
            },
            child: Text(
              context.l10n.deletePermanently,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class PetitionListTab extends StatelessWidget {
  const PetitionListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = PetitionRepository.create();
    return StreamBuilder<List<Petition>>(
      stream: repo.list(status: IConst.active),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final petitions = snapshot.data!;
        return ListView.builder(
          itemCount: petitions.length,
          itemBuilder: (context, index) {
            final petition = petitions[index];
            return ListTile(
              title: Text(petition.title),
              subtitle: Text(petition.status),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeletePetition(context, petition),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeletePetition(BuildContext context, Petition petition) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deletePetition),
        content: Text(context.l10n.areYouSureYouWantToDeleteThisPetition),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PetitionRepository.create().delete(petition.id);
              if (context.mounted) showSuccessSnackBar(context.l10n.deleted);
            },
            child: Text(
              context.l10n.deletePermanently,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
