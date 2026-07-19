import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/app/mobile/scaffolds/app_padding_scaffold.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/services/account_data_export_service.dart';
import 'package:stimmapp/core/data/services/file_output/export_file_format.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class ExportProfilePage extends StatefulWidget {
  const ExportProfilePage({super.key});

  @override
  State<ExportProfilePage> createState() => _ExportProfilePageState();
}

class _ExportProfilePageState extends State<ExportProfilePage> {
  bool _isExporting = false;

  Future<void> _exportAccountData() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await AccountDataExportService().saveCurrentUserData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountDataExportSuccess)),
      );
    } on CsvExportCanceledException {
      // The user closed the native save sheet.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.accountDataExportFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBarScaffold(
      title: context.l10n.exportAccountData,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: AppPaddingScaffold(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.exportAccountDataDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isExporting ? null : _exportAccountData,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: TriangleLoadingIndicator(
                        size: 18,
                        strokeWidth: 2,
                        showFill: false,
                      ),
                    )
                  : const Icon(Icons.save_alt_outlined),
              label: Text(context.l10n.exportAccountData),
            ),
          ],
        ),
      ),
    );
  }
}
