import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';

class CsvExportService extends ExportContentService {
  const CsvExportService();

  @override
  ExportFileFormat get format => ExportFileFormat.csv;

  @override
  String build(ExportDocument document) {
    final rows = document.hasDetails
        ? [
            for (final detail in document.details!)
              [detail.label, detail.value],
            const <String>[],
            [document.rowsTitle],
            ...document.rows,
          ]
        : document.rows;

    return const CsvEncoder().convert(rows);
  }

  @override
  Uint8List bytes(String content) {
    final bytes = utf8.encode(content);

    // UTF-8 BOM helps spreadsheet apps detect umlauts and other non-ASCII text.
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...bytes]);
  }
}
