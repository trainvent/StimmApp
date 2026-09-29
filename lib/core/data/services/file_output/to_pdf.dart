import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stimmapp/core/data/services/file_output/export_content_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';

class PdfExportService extends ExportContentService {
  const PdfExportService({this.slim = false});

  final bool slim;

  @override
  ExportFileFormat get format => ExportFileFormat.pdf;

  @override
  String build(ExportDocument document) {
    throw UnsupportedError('PDF exports are built as binary documents.');
  }

  @override
  Future<Uint8List> buildBytes(ExportDocument document) async {
    final pdf = pw.Document();
    if (slim) return _buildSlimPdf(document, pdf);
    final rows = document.rows;
    final headers = rows.isEmpty ? const <String>[] : rows.first;
    final signatureRows = rows.skip(1).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          if (!document.hasDetails && document.documentTitle != null) ...[
            pw.Text(
              document.documentTitle!,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
          ],
          if (document.hasDetails) ...[
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                for (final detail in document.details!)
                  [detail.label, detail.value],
              ],
              cellStyle: const pw.TextStyle(fontSize: 9),
              tableWidth: pw.TableWidth.max,
              columnWidths: {
                0: const pw.FixedColumnWidth(85),
                1: const pw.FlexColumnWidth(),
              },
            ),
            pw.SizedBox(height: 18),
          ],
          pw.Text(
            document.rowsTitle,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (headers.isNotEmpty)
            for (final entry in signatureRows.asMap().entries) ...[
              pw.Text(
                '${document.rowTitle} ${entry.key + 1}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  for (final field in headers.asMap().entries)
                    [
                      field.value,
                      field.key < entry.value.length
                          ? entry.value[field.key]
                          : '',
                    ],
                ],
                tableWidth: pw.TableWidth.max,
                columnWidths: {
                  0: const pw.FixedColumnWidth(85),
                  1: const pw.FlexColumnWidth(),
                },
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: PdfColors.grey500),
                cellPadding: const pw.EdgeInsets.all(5),
              ),
              pw.SizedBox(height: 12),
            ],
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _buildSlimPdf(
    ExportDocument document,
    pw.Document pdf,
  ) async {
    final rows = document.rows.skip(1);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          if (document.documentTitle case final title?) ...[
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
          ],
          if (document.hasDetails) ...[
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                for (final detail in document.details!)
                  [detail.label, detail.value],
              ],
              cellStyle: const pw.TextStyle(fontSize: 8),
              columnWidths: {0: const pw.FixedColumnWidth(105)},
              border: pw.TableBorder.all(color: PdfColors.grey500),
              cellPadding: const pw.EdgeInsets.all(4),
            ),
            pw.SizedBox(height: 14),
          ],
          pw.Text(
            document.rowsTitle,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: [
              '#',
              ...document.compactColumns.map((column) => column.label),
            ],
            data: [
              for (final entry in rows.toList().asMap().entries)
                [
                  '${entry.key + 1}',
                  ...document.compactColumns.map(
                    (column) => column.sourceIndex < entry.value.length
                        ? entry.value[column.sourceIndex]
                        : '',
                  ),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(68),
              2: const pw.FixedColumnWidth(72),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.8),
            },
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey100,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey500),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
      ),
    );
    return pdf.save();
  }
}
