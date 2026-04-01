import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/banner_ad_widget.dart';
import 'package:stimmapp/app/mobile/widgets/search_text_field.dart';
import 'package:stimmapp/app/mobile/widgets/tag_selector.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/eu_country_codes.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/poll_group.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/services/ad_consent_service.dart';

class BaseOverviewPage<T extends HomeItem> extends StatefulWidget {
  const BaseOverviewPage({
    super.key,
    required this.streamProvider,
    required this.itemBuilder,
    this.extraFilter,
    this.extraFilterCount = 0,
    this.filterDialogSectionBuilder,
    this.clearExtraFilters,
  });

  final Stream<List<T>> Function(String query, String status) streamProvider;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool Function(T item)? extraFilter;
  final int extraFilterCount;
  final Widget Function(BuildContext context, StateSetter setDialogState)?
  filterDialogSectionBuilder;
  final VoidCallback? clearExtraFilters;

  @override
  State<BaseOverviewPage<T>> createState() => _BaseOverviewPageState<T>();
}

class _BaseOverviewPageState<T extends HomeItem>
    extends State<BaseOverviewPage<T>>
    with SingleTickerProviderStateMixin {
  static const int _itemsPerAd = 7; // Show an ad after every 7 items.
  static const List<FormScopeType> _scopeFilterOrder = [
    FormScopeType.global,
    FormScopeType.eu,
    FormScopeType.country,
    FormScopeType.stateOrRegion,
    FormScopeType.city,
  ];

  late TabController _tabController;
  String _query = '';
  List<String> _selectedTags = [];
  Set<FormScopeType> _selectedScopes = {};
  bool _onlyMyPublications = false;
  Future<UserProfile?>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final uid = authService.currentUser?.uid;
    if (uid != null) {
      _userProfileFuture = UserRepository.create().getById(uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Use a local state for the dialog to allow updating selection before confirming
        List<String> tempSelectedTags = List.from(_selectedTags);
        Set<FormScopeType> tempSelectedScopes = Set.from(_selectedScopes);
        bool tempOnlyMyPublications = _onlyMyPublications;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.l10n.filter), // Using "Settings" or "Filter"
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpansionTile(
                      initiallyExpanded: true,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        context.l10n.scope,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      children: [
                        _buildScopeTargetSelector(
                          selectedScopes: tempSelectedScopes,
                          onToggle: (scope) {
                            setState(() {
                              if (tempSelectedScopes.contains(scope)) {
                                tempSelectedScopes.remove(scope);
                              } else {
                                tempSelectedScopes.add(scope);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    ExpansionTile(
                      initiallyExpanded: false,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        context.l10n.tags,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      children: [
                        TagSelector(
                          selectedTags: tempSelectedTags,
                          maxTags: 10, // Allow more tags for filtering
                          onChanged: (newTags) {
                            setState(() {
                              tempSelectedTags = newTags;
                            });
                          },
                        ),
                      ],
                    ),
                    if (widget.filterDialogSectionBuilder != null) ...[
                      const Divider(),
                      ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: Text(
                          context.l10n.groupsLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        children: [
                          widget.filterDialogSectionBuilder!(context, setState),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear filters
                    setState(() {
                      tempSelectedTags = [];
                      tempSelectedScopes = {};
                      tempOnlyMyPublications = false;
                    });
                    widget.clearExtraFilters?.call();
                  },
                  child: Text(context.l10n.remove),
                ),
                FilledButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedTags = tempSelectedTags;
                      _selectedScopes = tempSelectedScopes;
                      _onlyMyPublications = tempOnlyMyPublications;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isVisibleForUser({required T item, required UserProfile? userProfile}) {
    final userCountryCode =
        userProfile?.countryCode?.toUpperCase() ??
        (userProfile?.supportsStateScope == true ? 'DE' : null);
    final userStateOrRegion = userProfile?.state;
    final userTown = userProfile?.town?.trim().toLowerCase();
    final itemCountryCode = item.countryCode?.toUpperCase();
    final itemStateOrRegion = item.stateOrRegion;
    final itemTown = item.town?.trim().toLowerCase();
    final normalizedScopeType = _normalizedScopeType(item);

    switch (normalizedScopeType) {
      case 'global':
        return true;
      case 'eu':
        return isEuCountryCode(userCountryCode);
      case 'continent':
        if ((item.continentCode ?? '').toUpperCase() == 'EU') {
          return isEuCountryCode(userCountryCode);
        }
        return true;
      case 'country':
        if (userCountryCode == null || userCountryCode.isEmpty) return false;
        if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
        return userCountryCode == itemCountryCode;
      case 'stateOrRegion':
        if (userCountryCode == null || userCountryCode.isEmpty) return false;
        if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
        if (userCountryCode != itemCountryCode) return false;
        if (itemStateOrRegion == null || itemStateOrRegion.isEmpty) {
          return true;
        }
        return userStateOrRegion == itemStateOrRegion;
      case 'city':
      case 'town':
        if (userCountryCode == null || userCountryCode.isEmpty) return false;
        if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
        if (userCountryCode != itemCountryCode) return false;
        if (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty) {
          if (userStateOrRegion != itemStateOrRegion) return false;
        }
        if (itemTown == null || itemTown.isEmpty) {
          return true;
        }
        if (userTown == null || userTown.isEmpty) return false;
        return userTown == itemTown;
      default:
        return true;
    }
  }

  String _normalizedScopeType(T item) {
    final itemCountryCode = item.countryCode?.toUpperCase();
    final itemStateOrRegion = item.stateOrRegion;
    final itemTown = item.town?.trim().toLowerCase();
    final hasLegacyScopeData =
        (itemCountryCode != null && itemCountryCode.isNotEmpty) ||
        (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty) ||
        (itemTown != null && itemTown.isNotEmpty);

    return item.scopeType.isEmpty
        ? (itemTown != null && itemTown.isNotEmpty
              ? 'city'
              : (hasLegacyScopeData
                    ? (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty
                          ? 'stateOrRegion'
                          : 'country')
                    : 'global'))
        : item.scopeType;
  }

  bool _matchesSelectedScopes(T item) {
    if (_selectedScopes.isEmpty) {
      return true;
    }
    final normalizedScopeType = _normalizedScopeType(item);
    return _selectedScopes.any(
      (scope) => formScopeTypeToFirestore(scope) == normalizedScopeType,
    );
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

  String _scopeLabel(FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
        return context.l10n.scopeGlobal;
      case FormScopeType.eu:
        return context.l10n.scopeEu;
      case FormScopeType.continent:
        return context.l10n.scopeContinent;
      case FormScopeType.country:
        return context.l10n.scopeCountry;
      case FormScopeType.stateOrRegion:
        return context.l10n.scopeStateRegion;
      case FormScopeType.city:
        return context.l10n.scopeCity;
    }
  }

  Widget _buildScopeTargetSelector({
    required Set<FormScopeType> selectedScopes,
    required ValueChanged<FormScopeType> onToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    const sizes = <FormScopeType, double>{
      FormScopeType.global: 220,
      FormScopeType.eu: 180,
      FormScopeType.country: 140,
      FormScopeType.stateOrRegion: 100,
      FormScopeType.city: 60,
    };

    return Column(
      children: [
        Center(
          child: SizedBox(
            width: sizes[FormScopeType.global],
            height: sizes[FormScopeType.global],
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (final scope in _scopeFilterOrder)
                  _buildScopeRing(
                    scope: scope,
                    size: sizes[scope]!,
                    isSelected: selectedScopes.contains(scope),
                    onTap: () => onToggle(scope),
                    color: _scopeColor(colorScheme, scope),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final scope in _scopeFilterOrder)
              FilterChip(
                selected: selectedScopes.contains(scope),
                onSelected: (_) => onToggle(scope),
                avatar: CircleAvatar(
                  radius: 8,
                  backgroundColor: _scopeColor(colorScheme, scope),
                ),
                label: Text(_scopeLabel(scope)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildScopeRing({
    required FormScopeType scope,
    required double size,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? color.withValues(alpha: 0.22)
                  : color.withValues(alpha: 0.08),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.45),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.18),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: size <= 72
                ? Text(
                    _scopeLabel(scope),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Color _scopeColor(ColorScheme colorScheme, FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
        return colorScheme.primary;
      case FormScopeType.eu:
        return Colors.indigo;
      case FormScopeType.continent:
        return colorScheme.secondary;
      case FormScopeType.country:
        return Colors.teal;
      case FormScopeType.stateOrRegion:
        return Colors.orange;
      case FormScopeType.city:
        return Colors.redAccent;
    }
  }

  Widget _buildItemList(String status) {
    return FutureBuilder<UserProfile?>(
      future: _userProfileFuture,
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: TriangleLoadingIndicator());
        }
        final userProfile = userSnap.data;
        final currentUid = authService.currentUser?.uid;
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
                    return StreamBuilder<List<T>>(
                      stream: widget.streamProvider(_query, status),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: TriangleLoadingIndicator(),
                          );
                        }
                        var items = snap.data ?? const [];
                        items = items
                            .where(
                              (item) => _isVisibleForUser(
                                item: item,
                                userProfile: userProfile,
                              ),
                            )
                            .where(
                              (item) => _isAccessibleForCurrentUser(
                                item: item,
                                currentUid: currentUid,
                                memberGroupIds: memberGroupIds,
                                acceptedInviteGroupIds: acceptedInviteGroupIds,
                              ),
                            )
                            .toList();

                        if (blockedIds.isNotEmpty) {
                          items = items
                              .where(
                                (item) => !blockedIds.contains(item.createdBy),
                              )
                              .toList();
                        }

                        if (_onlyMyPublications && currentUid != null) {
                          items = items
                              .where((item) => item.createdBy == currentUid)
                              .toList();
                        }

                        if (_selectedTags.isNotEmpty) {
                          items = items.where((item) {
                            return item.tags.any(
                              (tag) => _selectedTags.contains(tag),
                            );
                          }).toList();
                        }

                        items = items.where(_matchesSelectedScopes).toList();
                        if (widget.extraFilter != null) {
                          items = items.where(widget.extraFilter!).toList();
                        }

                        if (items.isEmpty) {
                          return Center(child: Text(context.l10n.noData));
                        }
                        final showAds = AdConsentService.canShowAds(
                          userProfile,
                        );
                        final standardAdCount = showAds
                            ? (items.length / _itemsPerAd).floor()
                            : 0;
                        final showFallbackAd =
                            showAds && items.isNotEmpty && standardAdCount == 0;
                        final totalCount =
                            items.length +
                            standardAdCount +
                            (showFallbackAd ? 1 : 0);

                        return ListView.builder(
                          itemCount: totalCount,
                          itemBuilder: (context, index) {
                            if (!showAds) {
                              return Column(
                                children: [
                                  widget.itemBuilder(context, items[index]),
                                  const Divider(height: 1),
                                ],
                              );
                            }
                            final isAdTile =
                                (index + 1) % (_itemsPerAd + 1) == 0 ||
                                (showFallbackAd && index == totalCount - 1);
                            if (isAdTile) {
                              return const BannerAdWidget();
                            }
                            final adSlot = (index + 1) ~/ (_itemsPerAd + 1);
                            final itemIndex = index - adSlot;
                            return Column(
                              children: [
                                widget.itemBuilder(context, items[itemIndex]),
                                const Divider(height: 1),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate active filters count
    int filterCount = _selectedTags.length;
    filterCount += _selectedScopes.length;
    if (_onlyMyPublications) filterCount++;
    filterCount += widget.extraFilterCount;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kTextTabBarHeight),
        child: Material(
          color: Colors.transparent,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            indicatorColor: Theme.of(context).colorScheme.onSurface,
            dividerColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.18),
            tabs: [
              Tab(text: context.l10n.active),
              Tab(text: context.l10n.closed),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SearchTextField(
                    hint: context.l10n.searchTextField,
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _showFilterDialog,
                  icon: Badge(
                    isLabelVisible: filterCount > 0,
                    label: Text('$filterCount'),
                    child: const Icon(Icons.filter_list),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemList(IConst.active),
                  _buildItemList(IConst.closed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
