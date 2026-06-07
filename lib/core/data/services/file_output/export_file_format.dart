import 'package:flutter/widgets.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

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
