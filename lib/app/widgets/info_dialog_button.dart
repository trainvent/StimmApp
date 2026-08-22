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
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: content),
        ),
        actionsPadding: cornerImagePath.isEmpty ? null : EdgeInsets.zero,
        actions: [
          if (cornerImagePath.isEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.close),
            )
          else
            SizedBox(
              width: double.maxFinite,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: -38,
                    left: 0,
                    child: IgnorePointer(
                      child: LemmImage(assetPath: cornerImagePath),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(dialogContext.l10n.close),
                      ),
                    ),
                  ),
                ],
              ),
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
