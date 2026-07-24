import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stimmapp/app/pages/main/home/participants_list_page.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/data/di/service_locator.dart';
import 'package:stimmapp/core/data/services/database_service.dart';
import 'package:stimmapp/core/constants/app_tags_helper.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/config/environment.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class BaseDetailPage<T extends HomeItem> extends StatefulWidget {
  BaseDetailPage({
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
    AuthService? auth,
  }) : auth = auth ?? authService;

  final AuthService auth;

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

  @override
  State<BaseDetailPage<T>> createState() => _BaseDetailPageState<T>();
}

class _DiscoveryStatusBanner extends StatelessWidget {
  const _DiscoveryStatusBanner({
    required this.label,
    required this.icon,
    required this.isMuted,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final bool isMuted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isMuted ? colorScheme.secondary : colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _DiscoveryStatusPill extends StatelessWidget {
  const _DiscoveryStatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BaseDetailPageState<T extends HomeItem>
    extends State<BaseDetailPage<T>> {
  late Stream<T?> _itemStream;
  late Stream<T?> _topRightItemStream;

  @override
  void initState() {
    super.initState();
    _refreshItemStreams();
  }

  @override
  void didUpdateWidget(covariant BaseDetailPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id) {
      _refreshItemStreams();
    }
  }

  void _refreshItemStreams() {
    _itemStream = widget.streamProvider(widget.id);
    _topRightItemStream = widget.streamProvider(widget.id);
  }

  DatabaseService get _databaseService => locator.databaseService;

  String? _safeCurrentUid() {
    try {
      return widget.auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  bool _isAccessibleForCurrentUser({
    required T item,
    required String? currentUid,
    required Set<String> memberGroupIds,
  }) {
    final visibility = switch (item) {
      Poll(:final visibility) => visibility,
      Survey(:final visibility) => visibility,
      _ => 'public',
    };
    if (visibility != 'group') {
      return true;
    }

    if (currentUid == null) {
      return false;
    }

    if (item.createdBy == currentUid) {
      return true;
    }

    final groupId = switch (item) {
      Poll(:final groupId) => groupId,
      Survey(:final groupId) => groupId,
      _ => null,
    };
    if (groupId == null || groupId.isEmpty) {
      return false;
    }

    return memberGroupIds.contains(groupId);
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

    final groupName = _groupName(item);
    if ((groupName ?? '').trim().isNotEmpty) {
      chips.add(
        Chip(label: Text(context.l10n.groupLabelWithValue(groupName!.trim()))),
      );
    }

    return chips;
  }

  String? _groupName(T item) {
    return switch (item) {
      Poll(:final visibility, :final groupName) when visibility == 'group' =>
        groupName,
      Survey(:final visibility, :final groupName) when visibility == 'group' =>
        groupName,
      _ => null,
    };
  }

  bool _isGroupOnly(T item) {
    return switch (item) {
      Poll(:final visibility) => visibility == 'group',
      Survey(:final visibility) => visibility == 'group',
      _ => false,
    };
  }

  Widget _buildDiscoveryStatusBanner({
    required BuildContext context,
    required T item,
    required bool isExpired,
  }) {
    if (isExpired) {
      return const SizedBox.shrink();
    }

    final participantsStream = widget.participantsStream;
    if (participantsStream == null) {
      return _DiscoveryStatusBanner(
        label: context.l10n.eligibleForYou,
        icon: Icons.person_pin_circle_outlined,
        isMuted: false,
      );
    }

    return StreamBuilder<List<UserProfile>>(
      stream: participantsStream,
      builder: (context, snapshot) {
        final currentUid = _safeCurrentUid();
        final participants = snapshot.data ?? const <UserProfile>[];
        final hasParticipated =
            currentUid != null &&
            participants.any((profile) => profile.uid == currentUid);
        final label = hasParticipated
            ? context.l10n.alreadyParticipated
            : context.l10n.eligibleForYou;
        final icon = hasParticipated
            ? Icons.check_circle_outline
            : Icons.person_pin_circle_outlined;
        final groupName = _groupName(item)?.trim();
        return _DiscoveryStatusBanner(
          label: label,
          icon: icon,
          isMuted: hasParticipated,
          trailing: _isGroupOnly(item)
              ? _DiscoveryStatusPill(
                  icon: Icons.groups_2_outlined,
                  label: groupName == null || groupName.isEmpty
                      ? context.l10n.groupOnly
                      : groupName,
                )
              : null,
        );
      },
    );
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
        child: Material(
          type: MaterialType.transparency,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        actions: [
          if (widget.actions != null) ...widget.actions!,
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final link =
                  '${Environment.shareBaseUrl}/${widget.sharePathSegment}/${widget.id}';
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
          if (widget.topRightActionBuilder != null)
            StreamBuilder<T?>(
              stream: _topRightItemStream,
              builder: (context, snapshot) {
                final item = snapshot.data;
                if (item == null) {
                  return const SizedBox.shrink();
                }
                return widget.topRightActionBuilder!(context, item);
              },
            ),
        ],
      ),
      body: StreamBuilder<T?>(
        stream: _itemStream,
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
          return StreamBuilder<Set<String>>(
            stream: blockedIdsStream,
            builder: (context, blockedSnap) {
              final blockedIds = blockedSnap.data ?? const <String>{};
              return StreamBuilder<Set<String>>(
                stream: memberGroupIdsStream,
                builder: (context, groupSnap) {
                  final memberGroupIds = groupSnap.data ?? const <String>{};
                  if (!_isAccessibleForCurrentUser(
                    item: item,
                    currentUid: currentUid,
                    memberGroupIds: memberGroupIds,
                  )) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.l10n.groupOnlyUnavailable,
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
                        if (item.state != null && item.state!.isNotEmpty) ...[
                          Chip(
                            label: Text(
                              context.l10n.relatedToState(item.state!),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(item.description),
                        const SizedBox(height: 12),
                        _buildDiscoveryStatusBanner(
                          context: context,
                          item: item,
                          isExpired: isExpired,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${context.l10n.participants}: ${item.participantCount}',
                            ),
                            if (widget.participantsStream != null)
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ParticipantsListPage(
                                            participantsStream:
                                                widget.participantsStream!,
                                            signaturesStream:
                                                widget.signaturesStream,
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
                            child: widget.contentBuilder(context, item),
                          ),
                        ),
                        if (!isExpired && widget.bottomAction != null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: widget.bottomAction!,
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
      ),
    );
  }
}
