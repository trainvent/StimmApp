import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class AuthPopupLifecycle {
  AuthPopupLifecycle() {
    _blurListener = ((web.Event _) {
      _popupReceivedFocus = true;
    }).toJS;
    _focusListener = ((web.Event _) {
      if (!_popupReceivedFocus || _returned.isCompleted) return;
      _returnTimer?.cancel();
      // Give Firebase's popup promise a chance to complete first. This timer is
      // a fallback for browsers that never report popup-closed-by-user.
      _returnTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_returned.isCompleted) _returned.complete();
      });
    }).toJS;
    web.window.addEventListener('blur', _blurListener);
    web.window.addEventListener('focus', _focusListener);
  }

  final Completer<void> _returned = Completer<void>();
  late final JSFunction _blurListener;
  late final JSFunction _focusListener;
  Timer? _returnTimer;
  bool _popupReceivedFocus = false;

  Future<void> get returned => _returned.future;

  void dispose() {
    _returnTimer?.cancel();
    web.window.removeEventListener('blur', _blurListener);
    web.window.removeEventListener('focus', _focusListener);
  }
}
