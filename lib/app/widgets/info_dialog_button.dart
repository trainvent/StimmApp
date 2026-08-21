import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/lemm_image.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class InfoDialogButton extends StatelessWidget {
  const InfoDialogButton({
    super.key,
    required this.title,
    required this.content,
    this.cornerImagePath = "",
  });

  final String title;
  final Widget content;
  final String cornerImagePath;

  Future<void> _showInfoDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Stack(
        children: [
          AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(child: content),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogContext.l10n.close),
              ),
            ],
          ),
          if (cornerImagePath != "")
            const Positioned(
              bottom: 0,
              left: 0,
              child: IgnorePointer(child: LemmImage(assetPath: cornerImagePath)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.info,
      icon: const Icon(Icons.info_outline),
      onPressed: () => _showInfoDialog(context),
    );
  }
}
