import 'package:flutter/material.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class GoogleProfileRequirementsDialog extends StatelessWidget {
  const GoogleProfileRequirementsDialog({
    super.key,
    required this.onOpenGoogleProfile,
  });

  final Future<void> Function() onOpenGoogleProfile;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('googleProfileRequirementsDialog'),
      title: Text(context.l10n.completeGoogleProfile),
      content: Text(context.l10n.googleSyncRequiresCompleteProfile),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton.icon(
          key: const Key('openGoogleProfileFromRequirementsButton'),
          onPressed: () async {
            Navigator.of(context).pop();
            await onOpenGoogleProfile();
          },
          icon: const Icon(Icons.open_in_new),
          label: Text(context.l10n.editGoogleProfile),
        ),
      ],
    );
  }
}
