import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stimmapp/app/pages/others/outdated_page.dart';
import 'package:stimmapp/core/config/init.dart';
import 'package:stimmapp/core/providers/app_status_provider.dart';

import '../pages/others/app_loading_page.dart';
import 'app_root.dart';

class InitAppLayout extends ConsumerStatefulWidget {
  const InitAppLayout({super.key});

  @override
  ConsumerState<InitAppLayout> createState() => _InitAppLayoutState();
}

class _InitAppLayoutState extends ConsumerState<InitAppLayout> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<void> _initApp() async {
    final isOutdated = await checkIsAppVersionOutdated();
    ref.read(appOutdatedProvider.notifier).setOutdated(isOutdated);
  }

  @override
  Widget build(BuildContext context) {
    final isAppOutdated = ref.watch(appOutdatedProvider);

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage();
        }
        return isAppOutdated ? const OutdatedPage() : const AuthLayout();
      },
    );
  }
}
