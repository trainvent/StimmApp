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
          return Center(
            child: Text('Reports failed to load: ${snapshot.error}'),
          );
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ModerationReportReviewPage(report: report),
                  ),
                );
              },
              title: Text(
                '${report.contentType} • ${report.allReasons.join(', ')}',
              ),
              subtitle: Text(
                '${report.entries.length} notice(s)\n'
                'Reported user: ${report.reportedUserId}\n'
                'Content: ${report.contentId}\n'
                '${report.details ?? 'No additional details.'}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      },
    );
  }
}

class ModerationReportReviewPage extends StatefulWidget {
  const ModerationReportReviewPage({super.key, required this.report});

  final ModerationReport report;

  @override
  State<ModerationReportReviewPage> createState() =>
      _ModerationReportReviewPageState();
}

class _ModerationReportReviewPageState
    extends State<ModerationReportReviewPage> {
  final ModerationRepository _moderationRepo = ModerationRepository.create();
  bool _submitting = false;

  Future<_ModerationReviewData> _load() async {
    final report = widget.report;
    final creatorFuture = UserRepository.create().getById(
      report.reportedUserId,
    );

    if (report.contentType == 'petition') {
      final petition = await PetitionRepository.create().get(report.contentId);
      return _ModerationReviewData(
        report: report,
        creator: await creatorFuture,
        petition: petition,
      );
    }

    if (report.contentType == 'poll') {
      final poll = await PollRepository.create().get(report.contentId);
      return _ModerationReviewData(
        report: report,
        creator: await creatorFuture,
        poll: poll,
      );
    }

    return _ModerationReviewData(report: report, creator: await creatorFuture);
  }

  Future<void> _keepContent() async {
    setState(() => _submitting = true);
    try {
      await _moderationRepo.moderateReport(
        reportId: widget.report.id,
        action: 'keep',
      );
      if (!mounted) return;
      showSuccessSnackBar('Report marked as reviewed. Content kept.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _removeContent({required bool contentMissing}) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          contentMissing
              ? 'Dismiss missing report'
              : 'Remove content and kick user out',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contentMissing
                  ? 'The reported content no longer exists. This will resolve the report and remove it from the admin queue.'
                  : 'This removes the live content, archives it in Firestore, resolves the report, emails the creator, and deletes their account.',
            ),
            if (!contentMissing) ...[
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Optional message',
                  hintText: 'Add an extra note for the user',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(contentMissing ? 'Dismiss' : 'Remove'),
          ),
        ],
      ),
    );

    final adminMessage = controller.text;
    controller.dispose();
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await _moderationRepo.moderateReport(
        reportId: widget.report.id,
        action: 'remove',
        adminMessage: contentMissing ? null : adminMessage,
      );
      if (!mounted) return;
      showSuccessSnackBar(
        contentMissing
            ? 'Report dismissed. The missing content is no longer in the queue.'
            : 'Content removed, user notified, and account deleted.',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review report')),
      body: FutureBuilder<_ModerationReviewData>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load report: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: TriangleLoadingIndicator());
          }

          final data = snapshot.data!;
          final creator = data.creator;
          final report = data.report;
          final contentMissing = data.petition == null && data.poll == null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${report.contentType} report',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason: ${report.reason}'),
                      const SizedBox(height: 8),
                      Text('Report ID: ${report.id}'),
                      const SizedBox(height: 8),
                      Text('Reasons: ${report.allReasons.join(', ')}'),
                      const SizedBox(height: 8),
                      Text('Reported user ID: ${report.reportedUserId}'),
                      const SizedBox(height: 8),
                      Text('Content ID: ${report.contentId}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creator',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Name: ${creator?.displayName ?? 'Unknown'}'),
                      const SizedBox(height: 8),
                      Text('Email: ${creator?.email ?? 'Unknown'}'),
                      const SizedBox(height: 8),
                      Text('UID: ${report.reportedUserId}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report history',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...report.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${entry.source} • ${entry.reason}'),
                              const SizedBox(height: 4),
                              Text('Reporter: ${entry.reporterId}'),
                              if (entry.details != null &&
                                  entry.details!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(entry.details!),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ReportedContentCard(data: data),
              const SizedBox(height: 24),
              if (!contentMissing) ...[
                FilledButton(
                  onPressed: _submitting ? null : _keepContent,
                  child: Text(_submitting ? 'Processing...' : 'Keep content'),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _submitting
                    ? null
                    : () => _removeContent(contentMissing: contentMissing),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(
                  _submitting
                      ? 'Processing...'
                      : contentMissing
                      ? 'Dismiss report'
                      : 'Remove and notify',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportedContentCard extends StatelessWidget {
  const _ReportedContentCard({required this.data});

  final _ModerationReviewData data;

  @override
  Widget build(BuildContext context) {
    if (data.petition == null && data.poll == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'The reported content no longer exists. You can dismiss this report to remove it from the queue.',
          ),
        ),
      );
    }

    if (data.petition != null) {
      final petition = data.petition!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reported petition',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                petition.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(petition.description),
              const SizedBox(height: 12),
              Text('Status: ${petition.status}'),
              const SizedBox(height: 8),
              Text('Participants: ${petition.signatureCount}'),
              if (petition.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tags: ${petition.tags.join(', ')}'),
              ],
            ],
          ),
        ),
      );
    }

    final poll = data.poll!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reported poll',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(poll.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(poll.description),
            const SizedBox(height: 12),
            Text('Status: ${poll.status}'),
            const SizedBox(height: 8),
            Text('Votes: ${poll.totalVotes}'),
            const SizedBox(height: 12),
            ...poll.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${option.label} (${poll.votes[option.id] ?? 0})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModerationReviewData {
  const _ModerationReviewData({
    required this.report,
    this.creator,
    this.petition,
    this.poll,
  });

  final ModerationReport report;
  final UserProfile? creator;
  final Petition? petition;
  final Poll? poll;
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
