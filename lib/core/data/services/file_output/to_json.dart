import 'dart:convert';

import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';

class JsonExportService extends ExportContentService {
  const JsonExportService();

  @override
  ExportFileFormat get format => ExportFileFormat.json;

  @override
  String build(ExportDocument document) {
    final rows = document.rows;
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

    if (!document.hasDetails) {
      return const JsonEncoder.withIndent('  ').convert(items);
    }

    final details = {
      for (final detail in document.details!) detail.label: detail.value,
    };

    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'details': details, document.rowsTitle.toLowerCase(): items});
  }
}
