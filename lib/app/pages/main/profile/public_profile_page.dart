import 'package:stimmapp/app/pages/main/profile/profile_settings/public_profile_settings_dialog.dart';
import 'package:stimmapp/app/widgets/snackbar_utils.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/app/widgets/external_link_card.dart';
import 'package:stimmapp/core/functions/parse_website_link.dart';
import 'package:stimmapp/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stimmapp/core/data/models/public_profile.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/providers/public_profile_provider.dart';
import 'package:trainvent_general/trainvent_general.dart';

class PublicProfilePage extends ConsumerStatefulWidget {
  const PublicProfilePage({
    super.key,
    required this.userId,
    this.openSettings = false,
  });
  final String userId;
  final bool openSettings;

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage> {
  String get userId => widget.userId;
  bool _openingSettings = false;

  @override
  void initState() {
    super.initState();
    if (widget.openSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openSettings();
      });
    }
  }

  Future<void> _openSettings() async {
    if (_openingSettings || ref.read(currentUserProvider)?.uid != userId) {
      return;
    }
    setState(() => _openingSettings = true);
    try {
      final profile = await UserRepository.create().getById(userId);
      if (!mounted || profile == null) return;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PublicProfileSettingsDialog(profile: profile),
      );
      if (!mounted || saved != true) return;
      ref.invalidate(userProfileProvider);
      ref.invalidate(publicProfileProvider(userId));
      ref.invalidate(publicProfileFormsProvider(userId));
    } catch (_) {
      if (mounted) showUserMistakeSnackBar(context.l10n.profileSaveFailed);
    } finally {
      if (mounted) setState(() => _openingSettings = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.viewPublicProfile),
      actions: [
        if (ref.watch(currentUserProvider)?.uid == userId)
          IconButton(
            key: const ValueKey('public_profile_settings'),
            tooltip: context.l10n.publicProfileSettingsTitle,
            onPressed: _openingSettings ? null : _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
    ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _ProfileAvatar(profile: profile),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.nickname,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.nickname?.trim().isNotEmpty ==
                                              true
                                          ? profile.nickname!
                                          : context.l10n.unknownUser,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (profile.fullName?.trim().isNotEmpty == true ||
                              profile.address?.trim().isNotEmpty == true) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, thickness: 0.5),
                            ),
                            if (profile.fullName?.trim().isNotEmpty == true)
                              _ProfileDetail(
                                icon: Icons.person_outline,
                                label: context.l10n.publicProfileFullName,
                                value: profile.fullName!,
                              ),
                            if (profile.fullName?.trim().isNotEmpty == true &&
                                profile.address?.trim().isNotEmpty == true)
                              const SizedBox(height: 16),
                            if (profile.address?.trim().isNotEmpty == true)
                              _ProfileDetail(
                                icon: Icons.location_on_outlined,
                                label: context.l10n.address,
                                value: profile.address!,
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (parseWebsiteLink(profile.websiteUrl) case final uri?)
                      ExternalLinkCard(
                        uri: uri,
                        icon: Icons.link,
                        title: context.l10n.webLinkOpen,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.publications,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (profile.hidePublications)
                      _HiddenPublications()
                    else
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
                                            'poll' =>
                                              Icons.how_to_vote_outlined,
                                            _ => Icons.assignment_outlined,
                                          }),
                                          title: Text(
                                            form.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
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
                                                Localizations.localeOf(context)
                                                    .toLanguageTag(),
                                              ).format(form.createdAt),
                                            ].join(' · '),
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                          ),
                                          onTap: () =>
                                              Navigator.of(context)
                                                  .pushNamed(form.route),
                                        ),
                                    ],
                                  ),
                          ),
                  ],
                ),
        ),
  );
}

class _ProfileDetail extends StatelessWidget {
  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    ],
  );
}

class _HiddenPublications extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('publications_hidden'),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          child: Icon(
            Icons.lock_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.profilePublicationsHidden,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.profilePublicationsHiddenDescription,
          textAlign: TextAlign.center,
        ),
      ],
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
