import 'package:flutter_riverpod/flutter_riverpod.dart';

final appOutdatedProvider = NotifierProvider<AppOutdatedController, bool>(
  AppOutdatedController.new,
);

class AppOutdatedController extends Notifier<bool> {
  @override
  bool build() => false;

  void setOutdated(bool isOutdated) {
    state = isOutdated;
  }
}
