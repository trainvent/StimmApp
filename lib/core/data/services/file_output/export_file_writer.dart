import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';
import 'package:universal_io/io.dart';

class ExportFileWriter {
  const ExportFileWriter(this._databaseService);

  final DatabaseService _databaseService;

  String _fileName(String baseName, ExportContentService contentService) {
    final date = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final sanitizedBaseName = baseName
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${sanitizedBaseName}_$date.${contentService.format.extension}';
  }

  Future<String> save(
    String baseName,
    String content,
    ExportContentService contentService,
  ) async {
    final fileName = _fileName(baseName, contentService);
    await _disableNetwork();

    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [contentService.format.extension],
        bytes: contentService.bytes(content),
      );
      if (path == null) {
        throw const CsvExportCanceledException();
      }
      return path;
    } finally {
      await _enableNetwork();
    }
  }

  Future<String> share(
    String baseName,
    String content,
    ExportContentService contentService,
  ) async {
    final fileName = _fileName(baseName, contentService);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(contentService.bytes(content));
    await _disableNetwork();

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: contentService.format.mimeType)],
          text: 'Export: $fileName',
        ),
      );
      return file.path;
    } finally {
      await _enableNetwork();
    }
  }

  Future<void> _disableNetwork() async {
    try {
      // Native file/share sheets may background the app; pause Firestore
      // reconnect attempts while that happens.
      await _databaseService.disableNetwork();
    } catch (e) {
      debugPrint('Failed to disable Firestore network: $e');
    }
  }

  Future<void> _enableNetwork() async {
    try {
      await _databaseService.enableNetwork();
    } catch (e) {
      debugPrint('Failed to re-enable Firestore network: $e');
    }
  }
}
