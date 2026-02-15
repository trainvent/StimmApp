import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/notifiers/quota_update_notifier.dart';

class RunningFormsPage extends StatefulWidget {
  const RunningFormsPage({super.key});

  @override
  State<RunningFormsPage> createState() => _RunningFormsPageState();
}

class _RunningFormsPageState extends State<RunningFormsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Petition>> _runningPetitionsByMe() {
    return PetitionRepository.create()
        .list(query: null, status: IConst.active)
        .map((items) {
          final uid = authService.currentUser?.uid;
          final now = DateTime.now();
          return items
              .where((p) => p.createdBy == uid && p.expiresAt.isAfter(now))
              .toList();
        });
  }

  Stream<List<Poll>> _runningPollsByMe() {
    return PollRepository.create().list(query: null, status: IConst.active).map((
      items,
    ) {
      final uid = authService.currentUser?.uid;
      final now = DateTime.now();
      return items
          .where((p) => p.createdBy == uid && p.expiresAt.isAfter(now))
          .toList();
    });
  }

  Future<void> _deletePetition(Petition petition) async {
    final hasNoSignatures = petition.signatureCount == 0;

    if (!hasNoSignatures) {
      showErrorSnackBar('Cannot delete: Petition has signatures.');
      return;
    }

    final confirm = await _showDeleteDialog();
    if (confirm == true) {
      await PetitionRepository.create().delete(petition.id);
      QuotaUpdateNotifier.instance.notify();
      if (mounted) {
        showSuccessSnackBar('Petition deleted');
      }
    }
  }

  Future<void> _deletePoll(Poll poll) async {
    final hasNoVotes = poll.totalVotes == 0;

    if (!hasNoVotes) {
      showErrorSnackBar('Cannot delete: Poll has votes.');
      return;
    }

    final confirm = await _showDeleteDialog();
    if (confirm == true) {
      await PollRepository.create().delete(poll.id);
      QuotaUpdateNotifier.instance.notify();
      if (mounted) {
        showSuccessSnackBar('Poll deleted');
      }
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Form'),
        content: const Text('Are you sure you want to delete this form?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Forms'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.petitions),
            Tab(text: context.l10n.polls),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPetitionsTab(), _buildPollsTab()],
      ),
    );
  }

  Widget _buildPetitionsTab() {
    return StreamBuilder<List<Petition>>(
      stream: _runningPetitionsByMe().map(
        (list) => list..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No running petitions found.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = items[i];
            final hasNoSignatures = p.signatureCount == 0;

            return ListTile(
              title: Text(p.title),
              subtitle: Text(
                'Expires: ${DateFormat('yyyy-MM-dd').format(p.expiresAt)}',
              ),
              trailing: hasNoSignatures
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePetition(p),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildPollsTab() {
    return StreamBuilder<List<Poll>>(
      stream: _runningPollsByMe().map(
        (list) => list..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No running polls found.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = items[i];
            final hasNoVotes = p.totalVotes == 0;

            return ListTile(
              title: Text(p.title),
              subtitle: Text(
                'Expires: ${DateFormat('yyyy-MM-dd').format(p.expiresAt)}',
              ),
              trailing: hasNoVotes
                  ? IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePoll(p),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
