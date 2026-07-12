import 'package:stimmapp/core/config/verify_app_connection.dart';
import 'package:stimmapp/core/errors/error_log_tool.dart';

import '../errors/error_message.dart';

Future<void> initApp() async {
  await initInternetChecker();
}

Future<void> initInternetChecker() async {
  try {
    await verifyAppConnection();
  } catch (e) {
    errorLogTool(
      exception: e,
      errorCustomMessage: ErrorMessage.thisIsNotWorking,
    );
  }
}

Future<bool> checkIsAppVersionOutdated() async {
  try {
    return false;
  } catch (e) {
    errorLogTool(
      exception: e,
      errorCustomMessage: ErrorMessage.thisIsNotWorking,
    );
    return false;
  }
}
