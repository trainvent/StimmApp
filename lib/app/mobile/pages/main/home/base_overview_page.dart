import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/banner_ad_widget.dart';
import 'package:stimmapp/app/mobile/widgets/search_text_field.dart';
import 'package:stimmapp/app/mobile/widgets/tag_selector.dart';
import 'package:stimmapp/app/mobile/widgets/triangle_loading_indicator.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
import 'package:stimmapp/core/data/repositories/moderation_repository.dart';
import 'package:stimmapp/core/data/repositories/user_repository.dart';
import 'package:stimmapp/core/data/services/auth_service.dart';
import 'package:stimmapp/core/extensions/context_extensions.dart';

class BaseOverviewPage<T extends HomeItem> extends StatefulWidget {
  const BaseOverviewPage({
    super.key,
    required this.streamProvider,
    required this.itemBuilder,
  });

  final Stream<List<T>> Function(String query, String status) streamProvider;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<BaseOverviewPage<T>> createState() => _BaseOverviewPageState<T>();
}

class _BaseOverviewPageState<T extends HomeItem>
    extends State<BaseOverviewPage<T>>
    with SingleTickerProviderStateMixin {
  static const int _itemsPerAd = 7; // Show an ad after every 7 items.

  late TabController _tabController;
  String _query = '';
  List<String> _selectedTags = [];
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
        bool tempOnlyMyPublications = _onlyMyPublications;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                context.l10n.settings,
              ), // Using "Settings" or "Filter"
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text(
                        context.l10n.myPetitions,
                      ), // Reusing "My Petitions" or similar key for "My Publications"
                      value: tempOnlyMyPublications,
                      onChanged: (val) {
                        setState(() {
                          tempOnlyMyPublications = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    Text(
                      context.l10n.tags,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear filters
                    setState(() {
                      tempSelectedTags = [];
                      tempOnlyMyPublications = false;
                    });
                  },
                  child: Text(context.l10n.remove),
                ),
                FilledButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedTags = tempSelectedTags;
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
    final itemCountryCode = item.countryCode?.toUpperCase();
    final itemStateOrRegion = item.stateOrRegion;

    final hasLegacyScopeData =
        (itemCountryCode != null && itemCountryCode.isNotEmpty) ||
        (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty);
    final normalizedScopeType = item.scopeType.isEmpty
        ? (hasLegacyScopeData
              ? (itemStateOrRegion != null && itemStateOrRegion.isNotEmpty
                    ? 'stateOrRegion'
                    : 'country')
              : 'global')
        : item.scopeType;

    switch (normalizedScopeType) {
      case 'global':
        return true;
      case 'continent':
        // Continent support is optional in the current app.
        // Treat this as globally visible until user continent is modeled.
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
        // City scoping is optional in the current app.
        // Without a user city in profile, fallback to country/state checks.
        if (userCountryCode == null || userCountryCode.isEmpty) return false;
        if (itemCountryCode == null || itemCountryCode.isEmpty) return false;
        if (userCountryCode != itemCountryCode) return false;
        if (itemStateOrRegion == null || itemStateOrRegion.isEmpty) {
          return true;
        }
        return userStateOrRegion == itemStateOrRegion;
      default:
        return true;
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
        return StreamBuilder<Set<String>>(
          stream: blockedIdsStream,
          builder: (context, blockedSnap) {
            final blockedIds = blockedSnap.data ?? const <String>{};
            return StreamBuilder<List<T>>(
              stream: widget.streamProvider(_query, status),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: TriangleLoadingIndicator());
                }
                var items = snap.data ?? const [];
                items = items
                    .where(
                      (item) => _isVisibleForUser(
                        item: item,
                        userProfile: userProfile,
                      ),
                    )
                    .toList();

                if (blockedIds.isNotEmpty) {
                  items = items
                      .where((item) => !blockedIds.contains(item.createdBy))
                      .toList();
                }

                if (_onlyMyPublications && currentUid != null) {
                  items = items
                      .where((item) => item.createdBy == currentUid)
                      .toList();
                }

                if (_selectedTags.isNotEmpty) {
                  items = items.where((item) {
                    return item.tags.any((tag) => _selectedTags.contains(tag));
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(child: Text(context.l10n.noData));
                }
                final showAds = !(userProfile?.isPro ?? false) && !kIsWeb;
                final standardAdCount = showAds
                    ? (items.length / _itemsPerAd).floor()
                    : 0;
                final showFallbackAd =
                    showAds && items.isNotEmpty && standardAdCount == 0;
                final totalCount =
                    items.length + standardAdCount + (showFallbackAd ? 1 : 0);

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
  }

  @override
  Widget build(BuildContext context) {
    // Calculate active filters count
    int filterCount = _selectedTags.length;
    if (_onlyMyPublications) filterCount++;

    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: context.l10n.active),
          Tab(text: context.l10n.closed),
        ],
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
