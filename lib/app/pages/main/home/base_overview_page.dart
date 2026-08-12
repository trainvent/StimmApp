import 'package:flutter/material.dart';
import 'package:stimmapp/app/widgets/search_text_field.dart';
import 'package:stimmapp/app/widgets/tag_selector.dart';
import 'package:trainvent_general/trainvent_general.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/form_scope.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/poll.dart';
import 'package:stimmapp/core/data/models/survey.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/poll_group_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';
import 'package:stimmapp/core/functions/form_scope_eligibility.dart';
import 'package:stimmapp/core/services/analytics_service.dart';

class BaseOverviewPage<T extends HomeItem> extends StatefulWidget {
  const BaseOverviewPage({
    super.key,
    required this.streamProvider,
    required this.itemBuilder,
    this.participatedIdsStreamProvider,
    this.participationKeyProvider,
    this.extraFilter,
    this.extraFilterCount = 0,
    this.designFilterSectionBuilder,
    this.filterDialogSectionBuilder,
    this.clearExtraFilters,
    this.appBarTitle,
    this.streamKey,
  });

  final Stream<List<T>> Function(String query, String status) streamProvider;
  final Widget Function(
    BuildContext context,
    T item,
    DiscoveryStatus discoveryStatus,
  )
  itemBuilder;
  final Stream<Set<String>> Function(String uid)? participatedIdsStreamProvider;
  final String Function(T item)? participationKeyProvider;
  final bool Function(T item)? extraFilter;
  final int extraFilterCount;
  final Widget Function(BuildContext context, StateSetter setDialogState)?
  designFilterSectionBuilder;
  final Widget Function(BuildContext context, StateSetter setDialogState)?
  filterDialogSectionBuilder;
  final VoidCallback? clearExtraFilters;
  final String? appBarTitle;
  final Object? streamKey;

  @override
  State<BaseOverviewPage<T>> createState() => _BaseOverviewPageState<T>();
}

class DiscoveryStatus {
  const DiscoveryStatus({
    required this.hasParticipated,
    required this.isFinished,
    required this.isGroupOnly,
    this.groupName,
  });

  final bool hasParticipated;
  final bool isFinished;
  final bool isGroupOnly;
  final String? groupName;
}

class DiscoveryStatusChips extends StatelessWidget {
  const DiscoveryStatusChips({super.key, required this.status});

  final DiscoveryStatus status;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (!status.isFinished && status.hasParticipated) {
      chips.add(
        _DiscoveryChip(
          icon: Icons.check_circle_outline,
          label: context.l10n.alreadyParticipated,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (status.isGroupOnly) {
      final groupName = status.groupName?.trim();
      chips.add(
        _DiscoveryChip(
          icon: Icons.groups_2_outlined,
          label: groupName == null || groupName.isEmpty
              ? context.l10n.groupOnly
              : groupName,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }
}

class _DiscoveryChip extends StatelessWidget {
  const _DiscoveryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
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

class _BaseOverviewPageState<T extends HomeItem>
    extends State<BaseOverviewPage<T>>
    with SingleTickerProviderStateMixin {
  static const List<FormScopeType> _scopeFilterOrder = [
    FormScopeType.global,
    FormScopeType.countryUnion,
    FormScopeType.country,
    FormScopeType.stateOrRegion,
    FormScopeType.city,
  ];

  late TabController _tabController;
  String _query = '';
  List<String> _selectedTags = [];
  Set<FormScopeType> _selectedScopes = {};
  Set<CountryUnion> _selectedCountryUnions = {};
  bool _onlyMyPublications = false;
  Future<UserProfile?>? _userProfileFuture;
  bool _hasLoggedSearchForSession = false;
  final Map<String, Stream<List<T>>> _itemStreams = {};
  final Map<String, Stream<Set<String>>> _blockedIdsStreams = {};
  final Map<String, Stream<Set<String>>> _memberGroupIdsStreams = {};
  final Map<String, Stream<Set<String>>> _participatedIdsStreams = {};

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

  @override
  void didUpdateWidget(covariant BaseOverviewPage<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamKey != widget.streamKey) {
      _itemStreams.clear();
      _participatedIdsStreams.clear();
    }
  }

  Stream<List<T>> _itemStream(String status) => _itemStreams.putIfAbsent(
    status,
    () => widget.streamProvider(_query, status),
  );

  Stream<Set<String>> _blockedIdsStream(String status, String? uid) =>
      _blockedIdsStreams.putIfAbsent(
        status,
        () => uid == null
            ? Stream<Set<String>>.value(const <String>{})
            : ModerationRepository.create().watchBlockedUserIds(uid),
      );

  Stream<Set<String>> _memberGroupIdsStream(String status, String? uid) =>
      _memberGroupIdsStreams.putIfAbsent(
        status,
        () => uid == null
            ? Stream<Set<String>>.value(const <String>{})
            : PollGroupRepository.create()
                  .watchGroupsForUser(uid)
                  .map((groups) => groups.map((group) => group.id).toSet()),
      );

  Stream<Set<String>> _participatedIdsStream(String status, String? uid) =>
      _participatedIdsStreams.putIfAbsent(
        status,
        () => uid == null || widget.participatedIdsStreamProvider == null
            ? Stream<Set<String>>.value(const <String>{})
            : widget.participatedIdsStreamProvider!(uid),
      );

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Use a local state for the dialog to allow updating selection before confirming
        List<String> tempSelectedTags = List.from(_selectedTags);
        Set<FormScopeType> tempSelectedScopes = Set.from(_selectedScopes);
        Set<CountryUnion> tempSelectedCountryUnions = Set.from(
          _selectedCountryUnions,
        );
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
                      initiallyExpanded: false,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        context.l10n.scope,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      children: [
                        _buildScopeTargetSelector(
                          selectedScopes: tempSelectedScopes,
                          selectedCountryUnions: tempSelectedCountryUnions,
                          onToggle: (scope) {
                            setState(() {
                              if (tempSelectedScopes.contains(scope)) {
                                tempSelectedScopes.remove(scope);
                              } else {
                                tempSelectedScopes.add(scope);
                              }
                            });
                          },
                          onCountryUnionToggle: (union) {
                            setState(() {
                              if (tempSelectedCountryUnions.contains(union)) {
                                tempSelectedCountryUnions.remove(union);
                              } else {
                                tempSelectedCountryUnions.add(union);
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
                    if (widget.designFilterSectionBuilder != null) ...[
                      const Divider(),
                      ExpansionTile(
                        initiallyExpanded: false,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: Text(
                          context.l10n.design,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        children: [
                          widget.designFilterSectionBuilder!(context, setState),
                        ],
                      ),
                    ],
                    if (widget.filterDialogSectionBuilder != null) ...[
                      const Divider(),
                      ExpansionTile(
                        initiallyExpanded: false,
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
                      tempSelectedCountryUnions = {};
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
                      _selectedCountryUnions = tempSelectedCountryUnions;
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

  bool _matchesSelectedScopes(T item) {
    return matchesFormScopeFilter(
      scope: item.scope,
      selectedTypes: _selectedScopes,
      selectedCountryUnions: _selectedCountryUnions,
    );
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

  bool _isGroupOnly(T item) {
    return switch (item) {
      Poll(:final visibility) => visibility == 'group',
      Survey(:final visibility) => visibility == 'group',
      _ => false,
    };
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

  String _scopeLabel(FormScopeType scope) {
    switch (scope) {
      case FormScopeType.global:
        return context.l10n.scopeGlobal;
      case FormScopeType.countryUnion:
        return context.l10n.scopeCountryUnion;
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

  String _countryUnionLabel(CountryUnion union) => switch (union) {
    CountryUnion.eu => context.l10n.scopeEu,
    CountryUnion.un => context.l10n.scopeUn,
  };

  Widget _buildScopeTargetSelector({
    required Set<FormScopeType> selectedScopes,
    required Set<CountryUnion> selectedCountryUnions,
    required ValueChanged<FormScopeType> onToggle,
    required ValueChanged<CountryUnion> onCountryUnionToggle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    const sizes = <FormScopeType, double>{
      FormScopeType.global: 220,
      FormScopeType.countryUnion: 180,
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
        if (selectedScopes.contains(FormScopeType.countryUnion)) ...[
          const SizedBox(height: 12),
          Text(
            context.l10n.selectCountryUnion,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final union in CountryUnion.values)
                FilterChip(
                  selected: selectedCountryUnions.contains(union),
                  onSelected: (_) => onCountryUnionToggle(union),
                  label: Text(_countryUnionLabel(union)),
                ),
            ],
          ),
        ],
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
      case FormScopeType.countryUnion:
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
        final blockedIdsStream = _blockedIdsStream(status, currentUid);
        final memberGroupIdsStream = _memberGroupIdsStream(status, currentUid);
        final participatedIdsStream = _participatedIdsStream(
          status,
          currentUid,
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
                  stream: participatedIdsStream,
                  builder: (context, participatedSnap) {
                    final participatedIds =
                        participatedSnap.data ?? const <String>{};
                    return StreamBuilder<List<T>>(
                      stream: _itemStream(status),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return const Center(
                            child: TriangleLoadingIndicator(),
                          );
                        }
                        var items = snap.data ?? const [];
                        items = items
                            .where(
                              (item) => _isAccessibleForCurrentUser(
                                item: item,
                                currentUid: currentUid,
                                memberGroupIds: memberGroupIds,
                              ),
                            )
                            .toList();

                        items = filterHomeItemsInUserZone(
                          items: items,
                          userProfile: userProfile,
                        );

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
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final discoveryStatus = DiscoveryStatus(
                              hasParticipated: participatedIds.contains(
                                widget.participationKeyProvider?.call(item) ??
                                    item.id,
                              ),
                              isFinished:
                                  status == IConst.closed ||
                                  item.status != IConst.active ||
                                  item.isExpiredAt(DateTime.now()),
                              isGroupOnly: _isGroupOnly(item),
                              groupName: _groupName(item),
                            );
                            return Column(
                              children: [
                                widget.itemBuilder(
                                  context,
                                  item,
                                  discoveryStatus,
                                ),
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
    if (_selectedScopes.contains(FormScopeType.countryUnion)) {
      filterCount += _selectedCountryUnions.length;
    }
    if (_onlyMyPublications) filterCount++;
    filterCount += widget.extraFilterCount;

    final tabBar = TabBar(
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
    );

    final appBarTitle = widget.appBarTitle;
    return Scaffold(
      appBar: appBarTitle == null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kTextTabBarHeight),
              child: Material(color: Colors.transparent, child: tabBar),
            )
          : AppBar(
              title: Text(appBarTitle),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(kTextTabBarHeight),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: tabBar,
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
                    onChanged: (q) {
                      final trimmedQuery = q.trim();
                      if (trimmedQuery.isEmpty) {
                        _hasLoggedSearchForSession = false;
                      } else if (!_hasLoggedSearchForSession &&
                          trimmedQuery.length >= 2) {
                        _hasLoggedSearchForSession = true;
                        AnalyticsService.instance.logSearchUsed(
                          queryLength: trimmedQuery.length,
                          filterCount: filterCount,
                        );
                      }
                      setState(() {
                        _query = q;
                        _itemStreams.clear();
                      });
                    },
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
