import 'dart:async';

class AuthPopupLifecycle {
  final Completer<void> _returned = Completer<void>();

  Future<void> get returned => _returned.future;

  void dispose() {}
}
