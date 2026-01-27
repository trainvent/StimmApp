import 'package:connectivity_plus/connectivity_plus.dart';

import '../notifiers/notifiers.dart';

bool isFirstRun = true;

Future<void> verifyAppConnection() async {
  // Check initial connectivity
  List<ConnectivityResult> connectivityResults = await Connectivity()
      .checkConnectivity();
  AppData.isConnectedNotifier.value = !connectivityResults.contains(
    ConnectivityResult.none,
  );

  // Listen for changes
  Connectivity().onConnectivityChanged.listen((
    List<ConnectivityResult> results,
  ) {
    AppData.isConnectedNotifier.value = !results.contains(
      ConnectivityResult.none,
    );
  });
}
