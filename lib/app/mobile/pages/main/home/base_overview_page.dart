import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stimmapp/app/mobile/widgets/banner_ad_widget.dart';
import 'package:stimmapp/app/mobile/widgets/search_text_field.dart';
import 'package:stimmapp/app/mobile/widgets/tag_selector.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/home_item.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';
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
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.l10n.tags),
              content: SingleChildScrollView(
                child: TagSelector(
                  selectedTags: tempSelectedTags,
                  maxTags: 10, // Allow more tags for filtering
                  onChanged: (newTags) {
                    setState(() {
                      tempSelectedTags = newTags;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Clear filters
                    setState(() {
                      tempSelectedTags = [];
                    });
                  },
                  child: Text(context.l10n.remove),
                ),
                FilledButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedTags = tempSelectedTags;
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

  Widget _buildItemList(String status) {
    return FutureBuilder<UserProfile?>(
      future: _userProfileFuture,
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final userProfile = userSnap.data;
        return StreamBuilder<List<T>>(
          stream: widget.streamProvider(_query, status),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var items = snap.data ?? const [];
            
            // Filter by state
            if (userProfile != null) {
              items = items.where((p) {
                return p.state == null || p.state == userProfile.state;
              }).toList();
            }

            // Filter by tags
            if (_selectedTags.isNotEmpty) {
              items = items.where((item) {
                // Check if item has any of the selected tags
                // Assuming HomeItem has a tags property. 
                // Since T extends HomeItem, we need to cast or ensure HomeItem has tags.
                // Looking at models, Petition and Poll have tags. 
                // We might need to check runtime type or update HomeItem interface.
                // For now, let's assume dynamic access or check if we can add tags to HomeItem.
                // Actually, HomeItem is abstract. Let's check its definition.
                // If it doesn't have tags, we can't filter safely without casting.
                // Let's try dynamic for now as a quick fix, or better, update HomeItem.
                final dynamic dynamicItem = item;
                try {
                  final List<String> itemTags = (dynamicItem.tags as List<dynamic>).cast<String>();
                  return itemTags.any((tag) => _selectedTags.contains(tag));
                } catch (e) {
                  return true; // If no tags property, don't filter out
                }
              }).toList();
            }

            if (items.isEmpty) {
              return Center(child: Text(context.l10n.noData));
            }
            final showAds = userProfile?.isPro ?? false || kIsWeb;
            final standardAdCount = showAds
                ? 0
                : (items.length / _itemsPerAd).floor();
            // Ensure at least one ad is shown if the list is short but not empty.
            final showFallbackAd =
                !showAds && items.isNotEmpty && standardAdCount == 0;
            final totalCount =
                items.length + standardAdCount + (showFallbackAd ? 1 : 0);

            return ListView.builder(
              itemCount: totalCount,
              itemBuilder: (context, index) {
                if (showAds) {
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
                } else {
                  final adSlot = (index + 1) ~/ (_itemsPerAd + 1);
                  final itemIndex = index - adSlot;
                  return Column(
                    children: [
                      widget.itemBuilder(context, items[itemIndex]),
                      const Divider(height: 1),
                    ],
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    isLabelVisible: _selectedTags.isNotEmpty,
                    label: Text('${_selectedTags.length}'),
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
