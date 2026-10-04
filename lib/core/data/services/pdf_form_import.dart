import 'dart:convert';
import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';
import 'package:stimmapp/core/data/models/form_import.dart';
import 'package:stimmapp/core/data/models/poll_template.dart';

class PdfFormImport {
  static const maxBytes = 10 * 1024 * 1024;
  static const maxCharacters = 100000;

  static Future<String> extract(Uint8List bytes) async {
    if (bytes.length > maxBytes) throw const FormatException('size');
    await pdfrxFlutterInitialize();
    final document = await PdfDocument.openData(bytes);
    try {
      if (document.pages.length > 50) throw const FormatException('size');
      final text = StringBuffer();
      for (final page in document.pages) {
        text.writeln((await page.loadText())?.fullText ?? '');
        if (text.length > maxCharacters) throw const FormatException('size');
      }
      final result = text.toString().trim();
      if (result.isEmpty) throw const FormatException('empty');
      return result;
    } finally {
      await document.dispose();
    }
  }

  /// Deliberately limited to explicit numbering; never guesses layout or content.
  static PollTemplate parse(String source, {required String type}) {
    if (source.length > maxCharacters) throw const FormatException('size');
    final lines = source
        .split(RegExp(r'\r\n?|\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) throw const FormatException('empty');
    final description = <String>[];
    final questions = <Map<String, dynamic>>[];
    final numbered = RegExp(r'^\d+[.)]\s+(.+)$');
    final choice = RegExp(r'^(?:[a-zA-Z][.)]|[-•☐□])\s+(.+)$');
    for (final line in lines.skip(1)) {
      final question = type == 'petition' ? null : numbered.firstMatch(line);
      if (question != null) {
        questions.add({'title': question.group(1)!, 'options': <String>[]});
      } else if (questions.isEmpty) {
        description.add(line);
      } else {
        final option = choice.firstMatch(line);
        if (option != null) {
          (questions.last['options'] as List<String>).add(option.group(1)!);
        } else {
          // Wrapped lines continue the preceding question or answer.
          final options = questions.last['options'] as List<String>;
          if (options.isEmpty) {
            questions.last['title'] = '${questions.last['title']} $line';
          } else {
            options[options.length - 1] = '${options.last} $line';
          }
        }
      }
    }
    for (final question in questions) {
      question['type'] = (question['options'] as List).isEmpty
          ? 'text'
          : 'multipleChoice';
    }
    return FormImport.parse(
      jsonEncode({
        'version': 1,
        'type': type,
        'title': lines.first,
        'description': description.join('\n'),
        if (type != 'petition') 'questions': questions,
      }),
      expectedType: type,
      allowedTags: {},
    );
  }
}
