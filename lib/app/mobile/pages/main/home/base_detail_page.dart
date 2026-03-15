import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stimmapp/app/mobile/pages/main/home/participants_list_page.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/constants/app_tags_helper.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class BaseDetailPage<T extends HomeItem> extends StatelessWidget {
  const BaseDetailPage({
    super.key,
    required this.id,
    required this.appBarTitle,
    required this.streamProvider,
    required this.contentBuilder,
    required this.sharePathSegment,
    this.bottomAction,
    this.participantsStream,
    this.signaturesStream,
    this.actions,
    this.topRightActionBuilder,
  });

  final String id;
  final String appBarTitle;
  final Stream<T?> Function(String id) streamProvider;
  final Widget Function(BuildContext context, T item) contentBuilder;
  final Widget? bottomAction;
  final Stream<List<UserProfile>>? participantsStream;
  final Stream<List<Map<String, dynamic>>>? signaturesStream;
  final List<Widget>? actions;
  final Widget Function(BuildContext context, T item)? topRightActionBuilder;
  final String sharePathSegment;

  DatabaseService get _databaseService => locator.databaseService;

  String? _safeCurrentUid() {
    try {
      return authService.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  bool _isAccessibleForCurrentUser({
    required T item,
    required String? currentUid,
    required Set<String> memberGroupIds,
    required Set<String> acceptedInviteGroupIds,
  }) {
    if (item is! Poll) {
      return true;
    }

    final poll = item;
    if (poll.visibility != 'group') {
      return true;
    }

    if (currentUid == null) {
      return false;
    }

    if (poll.createdBy == currentUid) {
      return true;
    }

    final groupId = poll.groupId;
    if (groupId == null || groupId.isEmpty) {
      return false;
    }

    return memberGroupIds.contains(groupId) ||
        acceptedInviteGroupIds.contains(groupId);
  }

  String _scopeLabel(BuildContext context, T item) {
    switch (item.scopeType) {
      case 'eu':
        return context.l10n.scopeEu;
      case 'continent':
        return item.continentCode?.toUpperCase() == 'EU'
            ? context.l10n.europeScopeLabel
            : context.l10n.scopeContinent;
      case 'country':
        return item.countryCode?.toUpperCase() ??
            context.l10n.countryScopeFallback;
      case 'stateOrRegion':
        if ((item.stateOrRegion ?? '').isNotEmpty) {
          return item.stateOrRegion!;
        }
        return item.countryCode?.toUpperCase() ??
            context.l10n.stateRegionScopeFallback;
      case 'city':
      case 'town':
        final town = item.town?.trim();
        if (town != null && town.isNotEmpty) {
          return town;
        }
        return context.l10n.cityScopeFallback;
      case 'global':
      default:
        return context.l10n.globalScopeLabel;
    }
  }

  List<Widget> _detailMetaChips(BuildContext context, T item) {
    final chips = <Widget>[
      Chip(
        label: Text(
          context.l10n.scopeLabelWithValue(_scopeLabel(context, item)),
        ),
      ),
    ];

    if (item is Poll &&
        item.visibility == 'group' &&
        (item.groupName ?? '').trim().isNotEmpty) {
      chips.add(
        Chip(
          label: Text(
            context.l10n.groupLabelWithValue(item.groupName!.trim()),
          ),
        ),
      );
    }

    return chips;
  }

  Widget _buildHeaderCard(BuildContext context, T item) {
    final hasTags = item.tags.isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _detailMetaChips(context, item),
              ),
            ),
            if (hasTags) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: item.tags.map((tagKey) {
                    return Chip(
                      label: Text(
                        AppTagsHelper.getLocalizedTag(context, tagKey),
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (actions != null) ...actions!,
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final link = '${Environment.shareBaseUrl}/$sharePathSegment/$id';
              final shareText = '${context.l10n.shareThis}: $link';
              final shareSubject = context.l10n.share;
              final linkCopiedText = context.l10n.linkCopiedToClipboard;
              final messenger = ScaffoldMessenger.of(context);

              if (kIsWeb) {
                await Clipboard.setData(ClipboardData(text: link));
                if (context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(linkCopiedText)),
                  );
                }
                return;
              }

              try {
                try {
                  await _databaseService.disableNetwork();
                } catch (e) {
                  debugPrint('Failed to disable Firestore network: $e');
                }

                await SharePlus.instance.share(
                  ShareParams(text: shareText, subject: shareSubject),
                );
              } catch (e) {
                debugPrint('Share failed: $e');
                if (context.mounted) {
                  // Fallback: Copy to clipboard
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(linkCopiedText)),
                    );
                  }
                }
              } finally {
                try {
                  await _databaseService.enableNetwork();
                } catch (e) {
                  debugPrint('Failed to re-enable Firestore network: $e');
                }
              }
            },
          ),
          if (topRightActionBuilder != null)
            StreamBuilder<T?>(
              stream: streamProvider(id),
              builder: (context, snapshot) {
                final item = snapshot.data;
                if (item == null) {
                  return const SizedBox.shrink();
                }
                return topRightActionBuilder!(context, item);
              },
            ),
        ],
      ),
      body: StreamBuilder<T?>(
        stream: streamProvider(id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: TriangleLoadingIndicator());
          }
          final item = snap.data;
          if (item == null) return Center(child: Text(context.l10n.notFound));
          final currentUid = _safeCurrentUid();
          final blockedIdsStream = currentUid == null
              ? Stream<Set<String>>.value(const <String>{})
              : ModerationRepository.create().watchBlockedUserIds(currentUid);
          final memberGroupIdsStream = currentUid == null
              ? Stream<Set<String>>.value(const <String>{})
              : PollGroupRepository.create()
                    .watchGroupsForUser(currentUid)
                    .map((groups) => groups.map((group) => group.id).toSet());
          final acceptedInviteGroupIdsStream = currentUid == null
              ? Stream<Set<String>>.value(const <String>{})
              : PollGroupRepository.create()
                    .watchNotifications(currentUid)
                    .map(
                      (notifications) => notifications
                          .where(
                            (notification) =>
                                notification.type ==
                                    PollGroupAccessNotificationType.invite &&
                                notification.status ==
                                    PollGroupAccessNotificationStatus.accepted,
                          )
                          .map((notification) => notification.groupId)
                          .toSet(),
                    );

          return StreamBuilder<Set<String>>(
            stream: blockedIdsStream,
            builder: (context, blockedSnap) {
              final blockedIds = blockedSnap.data ?? const <String>{};
              return StreamBuilder<Set<String>>(
                stream: memberGroupIdsStream,
                builder: (context, groupSnap) {
                  final memberGroupIds = groupSnap.data ?? const <String>{};
                  return StreamBuilder<Set<String>>(
                    stream: acceptedInviteGroupIdsStream,
                    builder: (context, acceptedInviteSnap) {
                      final acceptedInviteGroupIds =
                          acceptedInviteSnap.data ?? const <String>{};
                      if (!_isAccessibleForCurrentUser(
                        item: item,
                        currentUid: currentUid,
                        memberGroupIds: memberGroupIds,
                        acceptedInviteGroupIds: acceptedInviteGroupIds,
                      )) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.l10n.notFound,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (blockedIds.contains(item.createdBy)) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              context.l10n.blockedContentHidden,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final now = DateTime.now();
                      final isExpiredByTime = !item.expiresAt.isAfter(now);
                      final isClosedByStatus = item.status == IConst.closed;
                      final isExpired = isClosedByStatus || isExpiredByTime;
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderCard(context, item),
                            const SizedBox(height: 12),
                            if (item.state != null &&
                                item.state!.isNotEmpty) ...[
                              Chip(
                                label: Text(
                                  context.l10n.relatedToState(item.state!),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(item.description),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${context.l10n.participants}: ${item.participantCount}',
                                ),
                                if (participantsStream != null)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ParticipantsListPage(
                                                participantsStream:
                                                    participantsStream!,
                                                signaturesStream:
                                                    signaturesStream,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Text(context.l10n.viewParticipants),
                                  ),
                              ],
                            ),
                            Text(
                              '${context.l10n.expiresOn}: ${DateFormat('dd.MM.yyyy').format(item.expiresAt)}',
                            ),
                            if (isExpired) ...[
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.closed,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Expanded(
                              child: AbsorbPointer(
                                absorbing: isExpired,
                                child: contentBuilder(context, item),
                              ),
                            ),
                            if (!isExpired && bottomAction != null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: bottomAction!,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
