import 'dart:convert';
import 'dart:typed_data';

import 'package:stimmapp/core/data/services/file_output/export_document.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';

abstract class ExportContentService {
  const ExportContentService();

  ExportFileFormat get format;

  String build(ExportDocument document);

  Uint8List bytes(String content) {
    return Uint8List.fromList(utf8.encode(content));
  }
}
