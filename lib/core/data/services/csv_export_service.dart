import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:universal_io/io.dart';

import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/models/petition.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

import 'package:stimmapp/core/data/repositories/poll_repository.dart';
import 'package:stimmapp/core/data/repositories/petition_repository.dart';

class CsvExportService {
  CsvExportService._();
  static final CsvExportService instance = CsvExportService._();

  final DatabaseService databaseService = locator.databaseService;
  final PollRepository _pollRepo = PollRepository.create();
  final PetitionRepository _petitionRepo = PetitionRepository.create();

  String _buildCsv(List<List<String>> rows) {
    return const ListToCsvConverter().convert(rows);
  }

  String _buildJson(List<List<String>> rows) {
    if (rows.isEmpty) {
      return '[]';
    }
    final headers = rows.first;
    final items = rows.skip(1).map((row) {
      return {
        for (var i = 0; i < headers.length; i++)
          headers[i]: i < row.length ? row[i] : '',
      };
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(items);
  }

  String _buildPlainText(List<List<String>> rows) {
    return rows.map((row) => row.join('\t')).join('\n');
  }

  String _buildContent(List<List<String>> rows, ExportFileFormat format) {
    return switch (format) {
      ExportFileFormat.csv => _buildCsv(rows),
      ExportFileFormat.json => _buildJson(rows),
      ExportFileFormat.plainText => _buildPlainText(rows),
    };
  }

  Uint8List _textBytes(String content, ExportFileFormat format) {
    final bytes = utf8.encode(content);
    if (format != ExportFileFormat.csv) {
      return Uint8List.fromList(bytes);
    }

    // UTF-8 BOM helps spreadsheet apps detect umlauts and other non-ASCII text.
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...bytes]);
  }

  String _fileName(String baseName, ExportFileFormat format) {
    final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedBaseName = baseName
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${sanitizedBaseName}_$date.${format.extension}';
  }

  Future<String> _saveExport(
    String baseName,
    String content,
    ExportFileFormat format,
  ) async {
    final fileName = _fileName(baseName, format);
    try {
      // Temporarily disable Firestore network to avoid repeated reconnect attempts
      // while the native file picker may background the app/process.
      await databaseService.disableNetwork();
    } catch (e) {
      debugPrint('Failed to disable Firestore network: $e');
    }

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [format.extension],
        bytes: _textBytes(content, format),
      );
      if (path == null) {
        throw const CsvExportCanceledException();
      }
      return path;
    } finally {
      try {
        await databaseService.enableNetwork();
      } catch (e) {
        debugPrint('Failed to re-enable Firestore network: $e');
      }
    }
  }

  Future<String> _shareExport(
    String baseName,
    String content,
    ExportFileFormat format,
  ) async {
    final fileName = _fileName(baseName, format);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(_textBytes(content, format));

    try {
      // Temporarily disable Firestore network to avoid repeated reconnect attempts
      // while the native share sheet may background the app/process.
      await databaseService.disableNetwork();
    } catch (e) {
      debugPrint('Failed to disable Firestore network: $e');
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: format.mimeType)],
          text: 'Export: $fileName',
        ),
      );
      return file.path;
    } finally {
      try {
        await databaseService.enableNetwork();
      } catch (e) {
        debugPrint('Failed to re-enable Firestore network: $e');
      }
    }
  }

  // Petition export: each row is a signer (result = "signed")
  Future<String> savePetitionResults(
    BuildContext context,
    Petition petition,
    String petitionId, [
    ExportFileFormat format = ExportFileFormat.csv,
  ]) async {
    final rows = await _buildPetitionResultsRows(
      CsvExportLabels.fromContext(context),
      petitionId,
    );
    return _saveExport(
      'petition_${petition.title}',
      _buildContent(rows, format),
      format,
    );
  }

  Future<String> sharePetitionResults(
    BuildContext context,
    Petition petition,
    String petitionId, [
    ExportFileFormat format = ExportFileFormat.csv,
  ]) async {
    final rows = await _buildPetitionResultsRows(
      CsvExportLabels.fromContext(context),
      petitionId,
    );
    return _shareExport(
      'petition_${petition.title}',
      _buildContent(rows, format),
      format,
    );
  }

  Future<String> exportPetitionResults(
    BuildContext context,
    Petition petition,
    String petitionId,
  ) {
    return savePetitionResults(context, petition, petitionId);
  }

  Future<List<List<String>>> _buildPetitionResultsRows(
    CsvExportLabels labels,
    String petitionId,
  ) async {
    // Fetch signer profiles via the participants stream once
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

  // Poll export: per-user chosen option if available; otherwise aggregate only
  Future<String> savePollResults(
    BuildContext context,
    Poll poll,
    String pollId, [
    ExportFileFormat format = ExportFileFormat.csv,
  ]) async {
    final rows = await _buildPollResultsRows(
      CsvExportLabels.fromContext(context),
      poll,
      pollId,
    );
    return _saveExport(
      'poll_${poll.title}',
      _buildContent(rows, format),
      format,
    );
  }

  Future<String> sharePollResults(
    BuildContext context,
    Poll poll,
    String pollId, [
    ExportFileFormat format = ExportFileFormat.csv,
  ]) async {
    final rows = await _buildPollResultsRows(
      CsvExportLabels.fromContext(context),
      poll,
      pollId,
    );
    return _shareExport(
      'poll_${poll.title}',
      _buildContent(rows, format),
      format,
    );
  }

  Future<String> exportPollResults(
    BuildContext context,
    Poll poll,
    String pollId,
  ) {
    return savePollResults(context, poll, pollId);
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
        // try to determine selected option from user's votedPolls entry if available
        // fallback to empty result if not determinable here.
        rows.add([
          '', // option label unknown in this simplified lookup
          p.givenName ?? '',
          p.surname ?? '',
          p.email ?? '',
          p.address ?? '',
        ]);
      }
    } else {
      // Fallback: export aggregates if no per-user votes fetched
      rows.addAll(
        poll.votes.entries.map(
          (e) => ['${optionMap[e.key] ?? e.key}: ${e.value}', '', '', '', ''],
        ),
      );
    }

    return rows;
  }
}

enum ExportFileFormat {
  csv('csv', 'text/csv; charset=utf-8'),
  json('json', 'application/json; charset=utf-8'),
  plainText('txt', 'text/plain; charset=utf-8');

  const ExportFileFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

class CsvExportCanceledException implements Exception {
  const CsvExportCanceledException();
}

class CsvExportLabels {
  const CsvExportLabels({
    required this.result,
    required this.name,
    required this.surname,
    required this.email,
    required this.livingAddress,
    required this.reason,
  });

  factory CsvExportLabels.fromContext(BuildContext context) {
    return CsvExportLabels(
      result: context.l10n.result,
      name: context.l10n.name,
      surname: context.l10n.surname,
      email: context.l10n.email,
      livingAddress: context.l10n.livingAddress,
      reason: 'Reason',
    );
  }

  final String result;
  final String name;
  final String surname;
  final String email;
  final String livingAddress;
  final String reason;
}
