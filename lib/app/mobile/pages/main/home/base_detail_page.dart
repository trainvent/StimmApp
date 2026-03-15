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
                  ShareParams(
                    text: shareText,
                    subject: shareSubject,
                  ),
                );
              } catch (e) {
                debugPrint('Share failed: $e');
                if (context.mounted) {
                  // Fallback: Copy to clipboard
                  await Clipboard.setData(ClipboardData(text: link));
                  if (context.mounted) {
                    messenger.showSnackBar(SnackBar(content: Text(linkCopiedText)));
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
              : PollGroupRepository.create().watchGroupsForUser(currentUid).map(
                  (groups) => groups.map((group) => group.id).toSet(),
                );
          final acceptedInviteGroupIdsStream = currentUid == null
              ? Stream<Set<String>>.value(const <String>{})
              : PollGroupRepository.create().watchNotifications(currentUid).map(
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
                            if (item.state != null && item.state!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(context.l10n.relatedToState(item.state!)),
                              ),
                            ],
                            if (item.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: item.tags.map((tagKey) {
                                  return Chip(
                                    label: Text(
                                      AppTagsHelper.getLocalizedTag(
                                        context,
                                        tagKey,
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                ),
                              ],
                            ),
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
                                      color: Theme.of(context).colorScheme.error,
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
