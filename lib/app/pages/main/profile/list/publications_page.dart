import 'package:flutter/material.dart';
import 'package:stimmapp/app/pages/main/home/creator/petition_creator_page.dart';
import 'package:stimmapp/app/pages/main/home/creator/survey_creator_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/finished_forms/form_export_page.dart';
import 'package:stimmapp/app/pages/main/profile/list/running_forms_page.dart';
import 'package:stimmapp/app/scaffolds/app_bar_scaffold.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/theme/app_corner_radii.dart';

class PublicationsPage extends StatelessWidget {
  const PublicationsPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AppBarScaffold(
      title: context.l10n.publications,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: context.largeBorderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 40,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.publicationsHubTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.publicationsHubDescription,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _PublicationCard(
              icon: Icons.playlist_add_check_circle_outlined,
              title: context.l10n.runningForms,
              description: context.l10n.runningFormsDescription,
              onTap: () => _open(context, RunningFormsPage()),
            ),
            const SizedBox(height: 12),
            _PublicationCard(
              icon: Icons.inventory_2_outlined,
              title: context.l10n.finishedForms,
              description: context.l10n.finishedFormsDescription,
              onTap: () => _open(context, const FormExportPage()),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
