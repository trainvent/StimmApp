import 'package:flutter/material.dart';
import 'package:stimmapp/core/constants/database_collections.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
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
import 'package:stimmapp/core/data/services/file_output/to_csv.dart';
import 'package:stimmapp/core/data/services/file_output/to_json.dart';
import 'package:stimmapp/core/data/services/file_output/to_text.dart';

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
      ExportFileFormat.plainText => const TextExportService(),
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
    final rows = await _buildPetitionResultsRows(
      CsvExportLabels.fromContext(context),
      petitionId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _petitionDetails(petition) : null,
      rowsTitle: 'Signatures',
    );
    return _writer.save(
      'petition_${petition.title}',
      service.build(document),
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
    final rows = await _buildPetitionResultsRows(
      CsvExportLabels.fromContext(context),
      petitionId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _petitionDetails(petition) : null,
      rowsTitle: 'Signatures',
    );
    return _writer.share(
      'petition_${petition.title}',
      service.build(document),
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
    final rows = await _buildPollResultsRows(
      CsvExportLabels.fromContext(context),
      poll,
      pollId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _pollDetails(poll) : null,
      rowsTitle: 'Results',
    );
    return _writer.save('poll_${poll.title}', service.build(document), service);
  }

  Future<String> sharePollResults(
    BuildContext context,
    Poll poll,
    String pollId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final rows = await _buildPollResultsRows(
      CsvExportLabels.fromContext(context),
      poll,
      pollId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _pollDetails(poll) : null,
      rowsTitle: 'Results',
    );
    return _writer.share(
      'poll_${poll.title}',
      service.build(document),
      service,
    );
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
    final rows = await _buildSurveyResultsRows(
      CsvExportLabels.fromContext(context),
      survey,
      surveyId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _surveyDetails(survey) : null,
      rowsTitle: 'Results',
    );
    return _writer.save(
      'survey_${survey.title}',
      service.build(document),
      service,
    );
  }

  Future<String> shareSurveyResults(
    BuildContext context,
    Survey survey,
    String surveyId, [
    ExportFileFormat format = ExportFileFormat.csv,
    bool includeContent = false,
  ]) async {
    final service = _serviceFor(format);
    final rows = await _buildSurveyResultsRows(
      CsvExportLabels.fromContext(context),
      survey,
      surveyId,
    );
    final document = ExportDocument(
      rows: rows,
      details: includeContent ? _surveyDetails(survey) : null,
      rowsTitle: 'Results',
    );
    return _writer.share(
      'survey_${survey.title}',
      service.build(document),
      service,
    );
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
        'signed',
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
          'submitted',
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

  List<ExportDetail> _petitionDetails(Petition petition) {
    return _withoutEmptyValues([
      ExportDetail('Type', 'Petition'),
      ExportDetail('ID', petition.id),
      ExportDetail('Header', petition.title),
      ExportDetail('Body', petition.description),
      ExportDetail('Tags', petition.tags.join(', ')),
      ExportDetail('Signature count', petition.signatureCount.toString()),
      ExportDetail('Created by', petition.createdBy),
      ExportDetail('Created at', _formatDateTime(petition.createdAt)),
      ExportDetail(
        'Expires at',
        petition.expiresAt == null
            ? 'Open until closed'
            : _formatDateTime(petition.expiresAt!),
      ),
      ExportDetail('Status', petition.status),
      ExportDetail('Scope type', petition.scopeType),
      ExportDetail('Continent', petition.continentCode ?? ''),
      ExportDetail('Country', petition.countryCode ?? ''),
      ExportDetail('State or region', petition.stateOrRegion ?? ''),
      ExportDetail('Town', petition.town ?? ''),
      ExportDetail('Image URL', petition.imageUrl ?? ''),
    ]);
  }

  List<ExportDetail> _pollDetails(Poll poll) {
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
      ExportDetail('Type', 'Poll'),
      ExportDetail('ID', poll.id),
      ExportDetail('Header', poll.title),
      ExportDetail('Body', poll.description),
      ExportDetail('Tags', poll.tags.join(', ')),
      ExportDetail('Options', options),
      ExportDetail('Votes', votes),
      ExportDetail('Total votes', poll.totalVotes.toString()),
      ExportDetail('Created by', poll.createdBy),
      ExportDetail('Created at', _formatDateTime(poll.createdAt)),
      ExportDetail(
        'Expires at',
        poll.expiresAt == null
            ? 'Open until closed'
            : _formatDateTime(poll.expiresAt!),
      ),
      ExportDetail('Status', poll.status),
      ExportDetail('Scope type', poll.scopeType),
      ExportDetail('Continent', poll.continentCode ?? ''),
      ExportDetail('Country', poll.countryCode ?? ''),
      ExportDetail('State or region', poll.stateOrRegion ?? ''),
      ExportDetail('Town', poll.town ?? ''),
      ExportDetail('Group ID', poll.groupId ?? ''),
      ExportDetail('Group name', poll.groupName ?? ''),
      ExportDetail('Visibility', poll.visibility),
    ]);
  }

  List<ExportDetail> _surveyDetails(Survey survey) {
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
      ExportDetail('Type', 'Survey'),
      ExportDetail('ID', survey.id),
      ExportDetail('Header', survey.title),
      ExportDetail('Body', survey.description),
      ExportDetail('Tags', survey.tags.join(', ')),
      ExportDetail('Questions', questions),
      ExportDetail('Votes', votes),
      ExportDetail('Response count', survey.responseCount.toString()),
      ExportDetail('Created by', survey.createdBy),
      ExportDetail('Created at', _formatDateTime(survey.createdAt)),
      ExportDetail(
        'Expires at',
        survey.expiresAt == null
            ? 'Open until closed'
            : _formatDateTime(survey.expiresAt!),
      ),
      ExportDetail('Status', survey.status),
      ExportDetail('Scope type', survey.scopeType),
      ExportDetail('Continent', survey.continentCode ?? ''),
      ExportDetail('Country', survey.countryCode ?? ''),
      ExportDetail('State or region', survey.stateOrRegion ?? ''),
      ExportDetail('Town', survey.town ?? ''),
      ExportDetail('Group ID', survey.groupId ?? ''),
      ExportDetail('Group name', survey.groupName ?? ''),
      ExportDetail('Visibility', survey.visibility),
    ]);
  }

  List<ExportDetail> _withoutEmptyValues(List<ExportDetail> details) {
    return details.where((detail) => detail.value.trim().isNotEmpty).toList();
  }

  String _formatDateTime(DateTime value) {
    return value.toIso8601String();
  }
}
