import 'package:flutter/material.dart';
import 'package:stimmapp/app_entry.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// Show a floating success snackbar. [message] is optional.
void showSuccessSnackBar([String? message]) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  final messenger = ScaffoldMessenger.of(ctx);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(ctx).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      content: Text(message ?? '', style: AppTextStyles.m),
      showCloseIcon: true,
    ),
  );
}

/// Show a floating error snackbar. [message] is optional.
void showErrorSnackBar([String? message]) {
  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  final messenger = ScaffoldMessenger.of(ctx);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(ctx).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      content: Text(message ?? '', style: AppTextStyles.m),
      showCloseIcon: true,
    ),
  );
}

Future<void> showInternalDifficultiesSnackBar([
  Object? error,
  StackTrace? stackTrace,
]) async {
  debugPrint('Internal difficulties: $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }

  final ctx = navigatorKey.currentContext;
  if (ctx == null) return;
  final messenger = ScaffoldMessenger.of(ctx);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(ctx).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      content: Text(
        'We are having internal difficulties. Please try again shortly.',
        style: AppTextStyles.m,
      ),
      showCloseIcon: true,
      action: SnackBarAction(
        label: 'Report',
        onPressed: () async {
          final body = Uri.encodeComponent(
            'Please describe what happened.\n\n'
            'App: ${Environment.appName}\n'
            'Error: ${error ?? 'unknown'}\n',
          );
          final subject = Uri.encodeComponent(
            '${Environment.appName} problem report',
          );
          final uri = Uri.parse(
            'mailto:${Environment.supportEmail}?subject=$subject&body=$body',
          );
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    ),
  );
}
