import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stimmapp/app/mobile/pages/main/groups/group_entry_page.dart';
import 'package:stimmapp/app/mobile/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GroupAccessQrScannerPage extends StatefulWidget {
  const GroupAccessQrScannerPage({super.key});

  @override
  State<GroupAccessQrScannerPage> createState() =>
      _GroupAccessQrScannerPageState();
}

class _GroupAccessQrScannerPageState extends State<GroupAccessQrScannerPage> {
  bool _handledScan = false;

  void _handleCode(String rawValue) {
    if (_handledScan) {
      return;
    }
    final uri = Uri.tryParse(rawValue);
    final groupId = uri?.queryParameters['groupId'];
    if (groupId == null || groupId.isEmpty) {
      showErrorSnackBar(context.l10n.invalidGroupInviteQrCode);
      return;
    }
    _handledScan = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GroupEntryPage(groupId: groupId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanGroupQrCode)),
      body: MobileScanner(
        onDetect: (capture) {
          final rawValue = capture.barcodes.first.rawValue;
          if (rawValue == null) {
            return;
          }
          _handleCode(rawValue);
        },
      ),
    );
  }
}
