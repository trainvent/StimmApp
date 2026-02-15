import 'package:flutter/foundation.dart';

/// A simple notifier to signal that the publishing quota might have changed
/// (e.g. after creating or deleting a petition/poll).
class QuotaUpdateNotifier extends ChangeNotifier {
  static final QuotaUpdateNotifier instance = QuotaUpdateNotifier();

  void notify() {
    notifyListeners();
  }
}
