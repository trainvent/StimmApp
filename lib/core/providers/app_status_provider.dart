import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appOutdatedProvider = NotifierProvider<AppOutdatedController, bool>(
  AppOutdatedController.new,
);

final appConnectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initialResults = await connectivity.checkConnectivity();
  yield _hasConnection(initialResults);
  yield* connectivity.onConnectivityChanged.map(_hasConnection).distinct();
});

class AppOutdatedController extends Notifier<bool> {
  @override
  bool build() => false;

  void setOutdated(bool isOutdated) {
    state = isOutdated;
  }
}

bool _hasConnection(List<ConnectivityResult> results) {
  return !results.contains(ConnectivityResult.none);
}
