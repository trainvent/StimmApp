import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';

class TextExportService extends ExportContentService {
  const TextExportService();

  @override
  ExportFileFormat get format => ExportFileFormat.plainText;

  @override
  String build(ExportDocument document) {
    final table = document.rows.map((row) => row.join('\t')).join('\n');
    if (!document.hasDetails) {
      return table;
    }

    final details = document.details!
        .map((detail) => '${detail.label}: ${detail.value}')
        .join('\n');

    return '$details\n\n${document.rowsTitle}\n$table';
  }
}
