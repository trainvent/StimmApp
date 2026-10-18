import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/external_link_card.dart';
import 'package:stimmapp/core/data/models/publication_links.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class PublicationLinksView extends StatelessWidget {
  const PublicationLinksView({super.key, required this.links});

  final PublicationLinks links;

  @override
  Widget build(BuildContext context) {
    final video = PublicationLinks.youtubeUri(links.youtubeUrl);
    final website = PublicationLinks.websiteUri(links.websiteUrl);
    if (video == null && website == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (video != null)
          ExternalLinkCard(
            uri: video,
            icon: Icons.play_circle_outline,
            title: context.l10n.publicationWatchVideo,
          ),
        if (website != null)
          ExternalLinkCard(
            uri: website,
            icon: Icons.language,
            title: context.l10n.publicationOpenWebsite,
          ),
      ],
    );
  }
}
