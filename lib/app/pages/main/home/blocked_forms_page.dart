import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

final blockedFormsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, type) {
      return locator.databaseService.instance
          .collection('blockedForms')
          .where('contentType', isEqualTo: type)
          .snapshots()
          .map((snapshot) {
            final entries = snapshot.docs.map((doc) => doc.data()).toList();
            entries.sort(
              (
                a,
                b,
              ) => ((b['removedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
                  .compareTo(
                    (a['removedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
                  ),
            );
            return entries;
          });
    });

/// Read-only summaries, never the original content or private report records.
class BlockedFormsPage extends ConsumerWidget {
  const BlockedFormsPage({super.key, required this.contentType});
  final String contentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(blockedFormsProvider(contentType))
        .when(
          loading: () => const Center(child: TriangleLoadingIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () =>
                  ref.invalidate(blockedFormsProvider(contentType)),
              child: Text(context.l10n.blockedFormsError),
            ),
          ),
          data: (entries) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _BlockedFormsInfoButton(),
              ),
              if (entries.isEmpty) Text(context.l10n.blockedFormsEmpty),
              for (final entry in entries)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.block),
                    title: Text(
                      entry['title'] as String? ?? context.l10n.banned,
                    ),
                    subtitle: Text(
                      entry['guideline'] as String? ??
                          context.l10n.blockedSafeSummary,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => _BlockedFormDetail(entry: entry),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
  }
}

class _BlockedFormDetail extends StatelessWidget {
  const _BlockedFormDetail({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final removedAt = (entry['removedAt'] as Timestamp?)?.toDate();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.banned),
        actions: const [_BlockedFormsInfoButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            entry['title'] as String? ?? context.l10n.banned,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          Text(entry['summary'] as String? ?? context.l10n.blockedSafeSummary),
          if (removedAt != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.blockedRemovedAt),
              subtitle: Text(
                MaterialLocalizations.of(
                  context,
                ).formatFullDate(removedAt.toLocal()),
              ),
            ),
          if (entry['guideline'] != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.blockedGuideline),
              subtitle: Text(entry['guideline'] as String),
            ),
          if (entry['explanation'] != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.blockedExplanation),
              subtitle: Text(entry['explanation'] as String),
            ),
        ],
      ),
    );
  }
}

class BannedModeMarker extends StatelessWidget {
  const BannedModeMarker({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.blockedModeHint,
    onPressed: () => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.blockedModeHint))),
    icon: const Icon(Icons.block),
  );
}

class _BlockedFormsInfoButton extends StatelessWidget {
  const _BlockedFormsInfoButton();

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.info_outline),
    tooltip: context.l10n.blockedFormsInfo,
    onPressed: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.blockedFormsInfo),
        content: Text(context.l10n.blockedFormsNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    ),
  );
}
