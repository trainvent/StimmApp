import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLinkCard extends StatelessWidget {
  const ExternalLinkCard({
    super.key,
    required this.uri,
    required this.icon,
    required this.title,
  });
  final Uri uri;
  final IconData icon;
  final String title;

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // The destination might have no available external handler.
    }
    if (context.mounted) {
      showUserMistakeSnackBar(context.l10n.publicationLinkOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) => Card.outlined(
    margin: const EdgeInsets.only(top: 8),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(uri.host, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.open_in_new, size: 20),
      onTap: () => _open(context, uri),
    ),
  );
}
