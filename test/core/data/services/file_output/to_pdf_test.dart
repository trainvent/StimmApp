import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/to_pdf.dart';

void main() {
  test('builds a numbered signatures table PDF', () async {
    final bytes = await const PdfExportService().buildBytes(
      const ExportDocument(
        rows: [
          ['Result', 'Name', 'Email'],
          ['signed', 'Ada Lovelace', 'ada@example.com'],
          ['signed', 'Alan Turing', 'alan@example.com'],
        ],
      ),
    );

    expect(utf8.decode(bytes, allowMalformed: true), startsWith('%PDF-'));
    expect(bytes, contains(0x25));
  });
}
