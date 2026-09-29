import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_writer.dart';
import 'package:stimmapp/core/data/services/file_output/to_pdf.dart';
import 'package:stimmapp/core/data/services/file_output/to_csv.dart';
import 'package:stimmapp/core/data/services/file_output/to_json.dart';

export 'package:stimmapp/core/data/services/file_output/export_file_format.dart';

class FileFormatRouter {
  FileFormatRouter._();

  static final FileFormatRouter instance = FileFormatRouter._();

  final PollRepository _pollRepo = PollRepository.create();
  final PetitionRepository _petitionRepo = PetitionRepository.create();
  final UserRepository _userRepo = UserRepository.create();
  final ExportFileWriter _writer = ExportFileWriter(locator.databaseService);

  ExportContentService _serviceFor(ExportFileFormat format) {
    return switch (format) {
      ExportFileFormat.csv => const CsvExportService(),
      ExportFileFormat.json => const JsonExportService(),
      ExportFileFormat.pdf => const PdfExportService(),
      ExportFileFormat.pdfSlim => const PdfExportService(slim: true),
    };
  }

  Future<String> savePetitionResults(
    BuildContext context,
    Petition petition,
    String petitionId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final labels = ExportLabels.fromContext(context);
    final rows = await _buildPetitionResultsRows(
      CsvExportLabels.fromContext(context),
      petitionId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _petitionDetails(petition, labels) : null,
      rowsTitle: context.l10n.exportSignatures,
      rowTitle: context.l10n.exportSignature,
      documentTitle: petition.title,
      compactColumns: [
        ExportColumn(sourceIndex: 1, label: context.l10n.name),
        ExportColumn(sourceIndex: 2, label: context.l10n.surname),
        ExportColumn(sourceIndex: 4, label: context.l10n.livingAddress),
        ExportColumn(sourceIndex: 3, label: context.l10n.email),
      ],
    );
    return _writer.saveDocument(
      'petition_${petition.title}',
      document,
      service,
    );
  }

  Future<String> sharePetitionResults(
    BuildContext context,
    Petition petition,
    String petitionId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final labels = ExportLabels.fromContext(context);
    final rows = await _buildPetitionResultsRows(
      CsvExportLabels.fromContext(context),
      petitionId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _petitionDetails(petition, labels) : null,
      rowsTitle: context.l10n.exportSignatures,
      rowTitle: context.l10n.exportSignature,
      documentTitle: petition.title,
      compactColumns: [
        ExportColumn(sourceIndex: 1, label: context.l10n.name),
        ExportColumn(sourceIndex: 2, label: context.l10n.surname),
        ExportColumn(sourceIndex: 4, label: context.l10n.livingAddress),
        ExportColumn(sourceIndex: 3, label: context.l10n.email),
      ],
    );
    return _writer.shareDocument(
      'petition_${petition.title}',
      document,
      service,
    );
  }

  Future<String> exportPetitionResults(
    BuildContext context,
    Petition petition,
    String petitionId,
  ) {
    return savePetitionResults(context, petition, petitionId);
  }

  Future<String> savePollResults(
    BuildContext context,
    Poll poll,
    String pollId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final labels = ExportLabels.fromContext(context);
    final rows = await _buildPollResultsRows(
      CsvExportLabels.fromContext(context),
      poll,
      pollId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _pollDetails(poll, labels) : null,
      rowsTitle: context.l10n.exportResults,
      rowTitle: context.l10n.exportSignature,
      documentTitle: poll.title,
    );
    return _writer.saveDocument('poll_${poll.title}', document, service);
  }

  Future<String> sharePollResults(
    BuildContext context,
    Poll poll,
    String pollId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final labels = ExportLabels.fromContext(context);
    final rows = await _buildPollResultsRows(
      CsvExportLabels.fromContext(context),
      poll,
      pollId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _pollDetails(poll, labels) : null,
      rowsTitle: context.l10n.exportResults,
      rowTitle: context.l10n.exportSignature,
      documentTitle: poll.title,
    );
    return _writer.shareDocument('poll_${poll.title}', document, service);
  }

  Future<String> exportPollResults(
    BuildContext context,
    Poll poll,
    String pollId,
  ) {
    return savePollResults(context, poll, pollId);
  }

  Future<String> saveSurveyResults(
    BuildContext context,
    Survey survey,
    String surveyId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final labels = ExportLabels.fromContext(context);
    final rows = await _buildSurveyResultsRows(
      CsvExportLabels.fromContext(context),
      survey,
      surveyId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _surveyDetails(survey, labels) : null,
      rowsTitle: context.l10n.exportResults,
      rowTitle: context.l10n.exportSignature,
      documentTitle: survey.title,
    );
    return _writer.saveDocument('survey_${survey.title}', document, service);
  }

  Future<String> shareSurveyResults(
    BuildContext context,
    Survey survey,
    String surveyId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final labels = ExportLabels.fromContext(context);
    final rows = await _buildSurveyResultsRows(
      CsvExportLabels.fromContext(context),
      survey,
      surveyId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _surveyDetails(survey, labels) : null,
      rowsTitle: context.l10n.exportResults,
      rowTitle: context.l10n.exportSignature,
      documentTitle: survey.title,
    );
    return _writer.shareDocument('survey_${survey.title}', document, service);
  }

  Future<String> exportSurveyResults(
    BuildContext context,
    Survey survey,
    String surveyId,
  ) {
    return saveSurveyResults(context, survey, surveyId);
  }

  Future<List<List<String>>> _buildPetitionResultsRows(
    CsvExportLabels labels,
    String petitionId,
  ) async {
    final results = await _petitionRepo.getParticipantsWithSignaturesOnce(
      petitionId,
    );
    final rows = <List<String>>[];
    rows.add([
      labels.result,
      labels.name,
      labels.surname,
      labels.email,
      labels.livingAddress,
      labels.reason,
    ]);
    for (final r in results) {
      final p = r['profile'] as UserProfile;
      final reason = r['reason'] as String? ?? '';
      rows.add([
        labels.signed,
        p.givenName ?? '',
        p.surname ?? '',
        p.email ?? '',
        p.address ?? '',
        reason,
      ]);
    }
    return rows;
  }

  Future<List<List<String>>> _buildPollResultsRows(
    CsvExportLabels labels,
    Poll poll,
    String pollId,
  ) async {
    final profiles = await _pollRepo.getParticipantsOnce(pollId);
    final optionMap = {for (final o in poll.options) o.id: o.label};

    final rows = <List<String>>[];
    rows.add([
      labels.result,
      labels.name,
      labels.surname,
      labels.email,
      labels.livingAddress,
    ]);

    if (profiles.isNotEmpty) {
      for (final p in profiles.whereType<UserProfile>()) {
        rows.add([
          '',
          p.givenName ?? '',
          p.surname ?? '',
          p.email ?? '',
          p.address ?? '',
        ]);
      }
    } else {
      rows.addAll(
        poll.votes.entries.map(
          (e) => ['${optionMap[e.key] ?? e.key}: ${e.value}', '', '', '', ''],
        ),
      );
    }

    return rows;
  }

  Future<List<List<String>>> _buildSurveyResultsRows(
    CsvExportLabels labels,
    Survey survey,
    String surveyId,
  ) async {
    final responseSnap = await locator.database
        .collection(DatabaseCollections.surveys)
        .doc(surveyId)
        .collection(DatabaseCollections.responses)
        .get();
    final optionLabelsByQuestion = {
      for (final question in survey.questions)
        question.id: {
          for (final option in question.options) option.id: option.label,
        },
    };

    final rows = <List<String>>[
      [
        labels.result,
        labels.name,
        labels.surname,
        labels.email,
        labels.livingAddress,
        ...survey.questions.map((question) => question.title),
      ],
    ];

    if (responseSnap.docs.isNotEmpty) {
      for (final doc in responseSnap.docs) {
        final data = doc.data();
        final answers = Map<String, dynamic>.from(
          data['answers'] as Map? ?? const <String, dynamic>{},
        );
        final profile = await _userRepo.getById(doc.id);

        rows.add([
          labels.submitted,
          profile?.givenName ?? '',
          profile?.surname ?? '',
          profile?.email ?? '',
          profile?.address ?? '',
          for (final question in survey.questions)
            optionLabelsByQuestion[question.id]?[answers[question.id]] ??
                (answers[question.id] as String? ?? ''),
        ]);
      }
      return rows;
    }

    for (final question in survey.questions) {
      final votes = survey.questionVotes[question.id] ?? const <String, int>{};
      for (final option in question.options) {
        rows.add([
          '${question.title} - ${option.label}: ${votes[option.id] ?? 0}',
          '',
          '',
          '',
          '',
          ...List<String>.filled(survey.questions.length, ''),
        ]);
      }
    }

    return rows;
  }

  List<ExportDetail> _petitionDetails(Petition petition, ExportLabels labels) {
    return _withoutEmptyValues([
      ExportDetail(labels.type, labels.petition),
      ExportDetail(labels.id, petition.id),
      ExportDetail(labels.header, petition.title),
      ExportDetail(labels.body, petition.description),
      ExportDetail(labels.tags, petition.tags.join(', ')),
      ExportDetail(labels.signatureCount, petition.signatureCount.toString()),
      ExportDetail(labels.createdBy, petition.createdBy),
      ExportDetail(labels.createdAt, _formatDateTime(petition.createdAt)),
      ExportDetail(
        labels.expiresAt,
        petition.expiresAt == null
            ? labels.openUntilClosed
            : _formatDateTime(petition.expiresAt!),
      ),
      ExportDetail(labels.status, petition.status),
      ExportDetail(labels.scopeType, petition.scopeType),
      ExportDetail(labels.continent, petition.continentCode ?? ''),
      ExportDetail(labels.country, petition.countryCode ?? ''),
      ExportDetail(labels.stateOrRegion, petition.stateOrRegion ?? ''),
      ExportDetail(labels.town, petition.town ?? ''),
      ExportDetail(labels.imageUrl, petition.imageUrl ?? ''),
    ]);
  }

  List<ExportDetail> _pollDetails(Poll poll, ExportLabels labels) {
    final options = poll.options.map((option) => option.label).join(', ');
    final votes = poll.votes.entries
        .map((entry) {
          final optionIndex = poll.options.indexWhere(
            (option) => option.id == entry.key,
          );
          final label = optionIndex == -1
              ? null
              : poll.options[optionIndex].label;
          return '${label ?? entry.key}: ${entry.value}';
        })
        .join(', ');

    return _withoutEmptyValues([
      ExportDetail(labels.type, labels.poll),
      ExportDetail(labels.id, poll.id),
      ExportDetail(labels.header, poll.title),
      ExportDetail(labels.body, poll.description),
      ExportDetail(labels.tags, poll.tags.join(', ')),
      ExportDetail(labels.options, options),
      ExportDetail(labels.votes, votes),
      ExportDetail(labels.totalVotes, poll.totalVotes.toString()),
      ExportDetail(labels.createdBy, poll.createdBy),
      ExportDetail(labels.createdAt, _formatDateTime(poll.createdAt)),
      ExportDetail(
        labels.expiresAt,
        poll.expiresAt == null
            ? labels.openUntilClosed
            : _formatDateTime(poll.expiresAt!),
      ),
      ExportDetail(labels.status, poll.status),
      ExportDetail(labels.scopeType, poll.scopeType),
      ExportDetail(labels.continent, poll.continentCode ?? ''),
      ExportDetail(labels.country, poll.countryCode ?? ''),
      ExportDetail(labels.stateOrRegion, poll.stateOrRegion ?? ''),
      ExportDetail(labels.town, poll.town ?? ''),
      ExportDetail(labels.groupId, poll.groupId ?? ''),
      ExportDetail(labels.groupName, poll.groupName ?? ''),
      ExportDetail(labels.visibility, poll.visibility),
    ]);
  }

  List<ExportDetail> _surveyDetails(Survey survey, ExportLabels labels) {
    final questions = survey.questions
        .map((question) {
          final options = question.options
              .map((option) => option.label)
              .join(', ');
          return '${question.title} [$options]';
        })
        .join(' | ');
    final votes = survey.questions
        .map((question) {
          final optionCounts = survey.questionVotes[question.id] ?? const {};
          final optionVotes = question.options
              .map((option) {
                return '${option.label}: ${optionCounts[option.id] ?? 0}';
              })
              .join(', ');
          return '${question.title} [$optionVotes]';
        })
        .join(' | ');

    return _withoutEmptyValues([
      ExportDetail(labels.type, labels.survey),
      ExportDetail(labels.id, survey.id),
      ExportDetail(labels.header, survey.title),
      ExportDetail(labels.body, survey.description),
      ExportDetail(labels.tags, survey.tags.join(', ')),
      ExportDetail(labels.options, questions),
      ExportDetail(labels.votes, votes),
      ExportDetail(labels.responseCount, survey.responseCount.toString()),
      ExportDetail(labels.createdBy, survey.createdBy),
      ExportDetail(labels.createdAt, _formatDateTime(survey.createdAt)),
      ExportDetail(
        labels.expiresAt,
        survey.expiresAt == null
            ? labels.openUntilClosed
            : _formatDateTime(survey.expiresAt!),
      ),
      ExportDetail(labels.status, survey.status),
      ExportDetail(labels.scopeType, survey.scopeType),
      ExportDetail(labels.continent, survey.continentCode ?? ''),
      ExportDetail(labels.country, survey.countryCode ?? ''),
      ExportDetail(labels.stateOrRegion, survey.stateOrRegion ?? ''),
      ExportDetail(labels.town, survey.town ?? ''),
      ExportDetail(labels.groupId, survey.groupId ?? ''),
      ExportDetail(labels.groupName, survey.groupName ?? ''),
      ExportDetail(labels.visibility, survey.visibility),
    ]);
  }

  List<ExportDetail> _withoutEmptyValues(List<ExportDetail> details) {
    return details.where((detail) => detail.value.trim().isNotEmpty).toList();
  }

  String _formatDateTime(DateTime value) {
    return value.toIso8601String();
  }
}
