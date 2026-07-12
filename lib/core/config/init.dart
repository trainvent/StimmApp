import 'package:stimmapp/core/errors/error_log_tool.dart';

import '../errors/error_message.dart';

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
