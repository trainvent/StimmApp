import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/app/mobile/pages/main/profile/list/finished_forms/form_result_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/survey_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/data/services/file_output/file_format_router.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class FormExportPage extends StatefulWidget {
  const FormExportPage({super.key});

  @override
  State<FormExportPage> createState() => _FormExportPageState();
}

class _FormExportPageState extends State<FormExportPage> {
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

  Stream<List<Survey>> _expiredSurveysByMe() {
    return SurveyRepository.create()
        .list(query: null, status: IConst.closed)
        .map((items) {
          final uid = authService.currentUser?.uid;
          final now = DateTime.now();
          return items
              .where((s) => s.createdBy == uid && s.expiresAt.isBefore(now))
              .toList();
        });
  }

  Future<void> _handlePetitionTap(Petition petition) async {
    final action = await _selectFormAction();
    if (action == null || !mounted) return;
    if (action == _FormAction.viewResults) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormResultPage.petition(petition: petition),
        ),
      );
      return;
    }
    await _exportPetition(petition, action);
  }

  Future<void> _handlePollTap(Poll poll) async {
    final action = await _selectFormAction();
    if (action == null || !mounted) return;
    if (action == _FormAction.viewResults) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormResultPage.poll(poll: poll),
        ),
      );
      return;
    }
    await _exportPoll(poll, action);
  }

  Future<void> _handleSurveyTap(Survey survey) async {
    final action = await _selectFormAction();
    if (action == null || !mounted) return;
    if (action == _FormAction.viewResults) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FormResultPage.survey(survey: survey),
        ),
      );
      return;
    }
    await _exportSurvey(survey, action);
  }

  Future<void> _exportPetition(Petition petition, _FormAction action) async {
    final exportContext = context;
    final includeContent = await _selectIncludeContent(isPoll: false);
    if (includeContent == null || !exportContext.mounted) return;
    final format = await _selectExportFormat();
    if (format == null || !exportContext.mounted) return;

    try {
      if (action == _FormAction.save) {
        await FileFormatRouter.instance.savePetitionResults(
          exportContext,
          petition,
          petition.id,
          format,
          includeContent,
        );
      } else {
        await FileFormatRouter.instance.sharePetitionResults(
          exportContext,
          petition,
          petition.id,
          format,
          includeContent,
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

  Future<void> _exportPoll(Poll poll, _FormAction action) async {
    final exportContext = context;
    final includeContent = await _selectIncludeContent(isPoll: true);
    if (includeContent == null || !exportContext.mounted) return;
    final format = await _selectExportFormat();
    if (format == null || !exportContext.mounted) return;

    try {
      if (action == _FormAction.save) {
        await FileFormatRouter.instance.savePollResults(
          exportContext,
          poll,
          poll.id,
          format,
          includeContent,
        );
      } else {
        await FileFormatRouter.instance.sharePollResults(
          exportContext,
          poll,
          poll.id,
          format,
          includeContent,
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

  Future<void> _exportSurvey(Survey survey, _FormAction action) async {
    final exportContext = context;
    final includeContent = await _selectIncludeContent(isPoll: true);
    if (includeContent == null || !exportContext.mounted) return;
    final format = await _selectExportFormat();
    if (format == null || !exportContext.mounted) return;

    try {
      if (action == _FormAction.save) {
        await FileFormatRouter.instance.saveSurveyResults(
          exportContext,
          survey,
          survey.id,
          format,
          includeContent,
        );
      } else {
        await FileFormatRouter.instance.shareSurveyResults(
          exportContext,
          survey,
          survey.id,
          format,
          includeContent,
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

  Future<bool?> _selectIncludeContent({required bool isPoll}) {
    final resultsLabel = isPoll
        ? _resultsLabel(context)
        : _signaturesLabel(context);
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Text(_includeContentLabel(context)),
                subtitle: Text(_includeContentSubtitle(context, resultsLabel)),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.format_list_bulleted),
                title: Text(_resultsOnlyLabel(context, resultsLabel)),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_FormAction?> _selectFormAction() {
    return showModalBottomSheet<_FormAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: Text(_viewResultsLabel(context)),
                onTap: () => Navigator.pop(context, _FormAction.viewResults),
              ),
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(_downloadLabel(context)),
                onTap: () => Navigator.pop(context, _FormAction.save),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: Text(_exportLabel(context)),
                onTap: () => Navigator.pop(context, _FormAction.share),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<ExportFileFormat?> _selectExportFormat() {
    return showModalBottomSheet<ExportFileFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('CSV'),
                subtitle: const Text('.csv'),
                onTap: () => Navigator.pop(context, ExportFileFormat.csv),
              ),
              ListTile(
                leading: const Icon(Icons.data_object),
                title: const Text('JSON'),
                subtitle: const Text('.json'),
                onTap: () => Navigator.pop(context, ExportFileFormat.json),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Plain text'),
                subtitle: const Text('.txt'),
                onTap: () => Navigator.pop(context, ExportFileFormat.plainText),
              ),
            ],
          ),
        );
      },
    );
  }

  String _downloadLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Herunterladen'
        : 'Download';
  }

  String _viewResultsLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Endergebnis ansehen'
        : 'View final results';
  }

  String _exportLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Exportieren'
        : 'Export';
  }

  String _includeContentLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Inhalt mit exportieren'
        : 'Export with content';
  }

  String _includeContentSubtitle(BuildContext context, String resultsLabel) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Kopf, Text und Details oberhalb von $resultsLabel'
        : 'Header, body, and details above $resultsLabel';
  }

  String _resultsOnlyLabel(BuildContext context, String resultsLabel) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Nur $resultsLabel'
        : '$resultsLabel only';
  }

  String _signaturesLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Unterschriften'
        : 'signatures';
  }

  String _resultsLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'de'
        ? 'Ergebnisse'
        : 'results';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.finishedForms),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.petitions),
              Tab(text: context.l10n.polls),
              Tab(text: context.l10n.surveys),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPetitionsTab(context),
            _buildPollsTab(context),
            _buildSurveysTab(context),
          ],
        ),
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
              onTap: () => _handlePetitionTap(p),
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
              onTap: () => _handlePollTap(p),
            );
          },
        );
      },
    );
  }

  Widget _buildSurveysTab(BuildContext context) {
    return StreamBuilder<List<Survey>>(
      stream: _expiredSurveysByMe().map(
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
            final s = items[i];
            return ListTile(
              title: Text(s.title),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(s.expiresAt)),
              onTap: () => _handleSurveyTap(s),
            );
          },
        );
      },
    );
  }
}

enum _FormAction { viewResults, save, share }
