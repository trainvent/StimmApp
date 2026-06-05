import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/csv_export_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class FormExportPage extends StatefulWidget {
  const FormExportPage({super.key});

  @override
  State<FormExportPage> createState() => _FormExportPageState();
}

class _FormExportPageState extends State<FormExportPage>
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

  Stream<List<Petition>> _expiredPetitionsByMe() {
    return PetitionRepository.create()
        .list(query: null, status: IConst.closed)
        .map((items) {
          final uid = authService.currentUser?.uid;
          final now = DateTime.now();
          return items
              .where((p) => p.createdBy == uid && p.expiresAt.isBefore(now))
              .toList();
        });
  }

  Stream<List<Poll>> _expiredPollsByMe() {
    return PollRepository.create().list(query: null, status: IConst.closed).map(
      (items) {
        final uid = authService.currentUser?.uid;
        final now = DateTime.now();
        return items
            .where((p) => p.createdBy == uid && p.expiresAt.isBefore(now))
            .toList();
      },
    );
  }

  Future<void> _exportPetition(Petition petition) async {
    final exportContext = context;
    final action = await _selectExportAction();
    if (action == null || !exportContext.mounted) return;

    try {
      if (action == _CsvExportAction.save) {
        await CsvExportService.instance.savePetitionResults(
          exportContext,
          petition,
          petition.id,
        );
      } else {
        await CsvExportService.instance.sharePetitionResults(
          exportContext,
          petition,
          petition.id,
        );
      }
    } on CsvExportCanceledException {
      return;
    } on MissingPluginException {
      if (!mounted) return;
      showErrorSnackBar(context.l10n.notAvailableOnWebApp);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar('${context.l10n.exportFailed}: $e');
    }
  }

  Future<void> _exportPoll(Poll poll) async {
    final exportContext = context;
    final action = await _selectExportAction();
    if (action == null || !exportContext.mounted) return;

    try {
      if (action == _CsvExportAction.save) {
        await CsvExportService.instance.savePollResults(
          exportContext,
          poll,
          poll.id,
        );
      } else {
        await CsvExportService.instance.sharePollResults(
          exportContext,
          poll,
          poll.id,
        );
      }
    } on CsvExportCanceledException {
      return;
    } on MissingPluginException {
      if (!mounted) return;
      showErrorSnackBar(context.l10n.notAvailableOnWebApp);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar('${context.l10n.exportFailed}: $e');
    }
  }

  Future<_CsvExportAction?> _selectExportAction() {
    return showModalBottomSheet<_CsvExportAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(context.l10n.save),
                onTap: () => Navigator.pop(context, _CsvExportAction.save),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(context.l10n.share),
                onTap: () => Navigator.pop(context, _CsvExportAction.share),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.expiredCreations),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.expiredPetitions),
            Tab(text: context.l10n.expiredPolls),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPetitionsTab(context), _buildPollsTab(context)],
      ),
    );
  }

  Widget _buildPetitionsTab(BuildContext context) {
    return StreamBuilder<List<Petition>>(
      stream: _expiredPetitionsByMe().map(
        (list) => list..sort((a, b) => b.expiresAt.compareTo(a.expiresAt)),
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(context.l10n.noExpiredItems));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = items[i];
            return ListTile(
              title: Text(p.title),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(p.expiresAt)),
              trailing: TextButton(
                onPressed: () => _exportPetition(p),
                child: Text(context.l10n.exportCsv),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPollsTab(BuildContext context) {
    return StreamBuilder<List<Poll>>(
      stream: _expiredPollsByMe().map(
        (list) => list..sort((a, b) => b.expiresAt.compareTo(a.expiresAt)),
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(child: Text(context.l10n.noExpiredItems));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = items[i];
            return ListTile(
              title: Text(p.title),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(p.expiresAt)),
              trailing: TextButton(
                onPressed: () => _exportPoll(p),
                child: Text(context.l10n.exportCsv),
              ),
            );
          },
        );
      },
    );
  }
}

enum _CsvExportAction { save, share }
