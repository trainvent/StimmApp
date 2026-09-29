import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';

class PdfExportService extends ExportContentService {
  const PdfExportService();

  @override
  ExportFileFormat get format => ExportFileFormat.pdf;

  @override
  String build(ExportDocument document) {
    throw UnsupportedError('PDF exports are built as binary documents.');
  }

  @override
  Future<Uint8List> buildBytes(ExportDocument document) async {
    final pdf = pw.Document();
    final rows = document.rows;
    final headers = rows.isEmpty ? const <String>[] : rows.first;
    final signatureRows = rows.skip(1).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          if (document.hasDetails) ...[
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                for (final detail in document.details!)
                  [detail.label, detail.value],
              ],
              cellStyle: const pw.TextStyle(fontSize: 9),
              columnWidths: {0: const pw.FixedColumnWidth(130)},
            ),
            pw.SizedBox(height: 18),
          ],
          pw.Text(
            document.rowsTitle,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (headers.isNotEmpty)
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['#', ...headers],
              data: [
                for (final entry in signatureRows.asMap().entries)
                  [
                    '${entry.key + 1}',
                    ...List<String>.generate(
                      headers.length,
                      (index) =>
                          index < entry.value.length ? entry.value[index] : '',
                    ),
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey100,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey500),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
        ],
      ),
    );

    return pdf.save();
  }
}
