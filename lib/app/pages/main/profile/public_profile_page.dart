import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/core/data/models/public_profile.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/public_profile_provider.dart';
import 'package:trainvent_general/trainvent_general.dart';

class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.viewPublicProfile)),
    body: ref
        .watch(publicProfileProvider(userId))
        .when(
          loading: () => const Center(child: TriangleLoadingIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(publicProfileProvider(userId)),
              child: Text(context.l10n.erroneousProfile),
            ),
          ),
          data: (profile) => profile == null
              ? Center(child: Text(context.l10n.notFound))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.28),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          _ProfileAvatar(profile: profile),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.nickname,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.nickname?.trim().isNotEmpty == true
                                      ? profile.nickname!
                                      : context.l10n.unknownUser,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.publications,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ref
                        .watch(publicProfileFormsProvider(userId))
                        .when(
                          loading: () => const SizedBox(
                            height: 48,
                            child: Center(
                              child: TriangleLoadingIndicator(size: 24),
                            ),
                          ),
                          error: (_, _) => TextButton(
                            onPressed: () => ref.invalidate(
                              publicProfileFormsProvider(userId),
                            ),
                            child: Text(context.l10n.error),
                          ),
                          data: (forms) => forms.isEmpty
                              ? Text(context.l10n.noData)
                              : Column(
                                  children: [
                                    for (final form in forms)
                                      ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                        leading: Icon(switch (form.type) {
                                          'petition' => Icons.draw_outlined,
                                          'poll' => Icons.how_to_vote_outlined,
                                          _ => Icons.assignment_outlined,
                                        }),
                                        title: Text(
                                          form.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        subtitle: Text(
                                          [
                                            switch (form.type) {
                                              'petition' =>
                                                context.l10n.petition,
                                              'poll' => context.l10n.poll,
                                              _ => context.l10n.surveys,
                                            },
                                            DateFormat.yMMMd(
                                              Localizations.localeOf(
                                                context,
                                              ).toLanguageTag(),
                                            ).format(form.createdAt),
                                          ].join(' · '),
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                        ),
                                        onTap: () => Navigator.of(
                                          context,
                                        ).pushNamed(form.route),
                                      ),
                                  ],
                                ),
                        ),
                  ],
                ),
        ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});
  final PublicProfile profile;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(
        Icons.person_outline,
        size: 36,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
    return SizedBox.square(
      dimension: 72,
      child: ClipOval(
        child: profile.imageUrl?.isNotEmpty == true
            ? Image.network(
                profile.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
                frameBuilder: (_, child, frame, _) =>
                    frame == null ? fallback : child,
              )
            : fallback,
      ),
    );
  }
}
