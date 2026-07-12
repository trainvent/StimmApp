import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedMainPageProvider =
    NotifierProvider.autoDispose<MainNavigationNotifier, int>(
      MainNavigationNotifier.new,
    );

class MainNavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectPage(int index) {
    state = index;
  }
}
