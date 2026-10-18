import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/models/publication_links.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicationLinksView extends StatelessWidget {
  const PublicationLinksView({super.key, required this.links});

  final PublicationLinks links;

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
  Widget build(BuildContext context) {
    final video = PublicationLinks.youtubeUri(links.youtubeUrl);
    final website = PublicationLinks.websiteUri(links.websiteUrl);
    if (video == null && website == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (video != null)
          _card(
            context,
            video,
            Icons.play_circle_outline,
            context.l10n.publicationWatchVideo,
          ),
        if (website != null)
          _card(
            context,
            website,
            Icons.language,
            context.l10n.publicationOpenWebsite,
          ),
      ],
    );
  }

  Widget _card(BuildContext context, Uri uri, IconData icon, String title) =>
      Card.outlined(
        margin: const EdgeInsets.only(top: 8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(
            uri.host,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => _open(context, uri),
        ),
      );
}
