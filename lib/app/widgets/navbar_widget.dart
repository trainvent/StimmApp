import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/core/providers/navigation_provider.dart';
import '../pages/main/home/home_navigation_config.dart';

class NavbarWidget extends ConsumerWidget {
  const NavbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = mainPagesConfig(context);
    final selectedPage = ref.watch(selectedMainPageProvider);

    return NavigationBar(
      destinations: pages.map((config) {
        return NavigationDestination(
          icon: Icon(config.icon),
          label: config.title,
        );
      }).toList(),
      onDestinationSelected: (int value) {
        ref.read(selectedMainPageProvider.notifier).selectPage(value);
      },
      selectedIndex: selectedPage,
    );
  }
}
