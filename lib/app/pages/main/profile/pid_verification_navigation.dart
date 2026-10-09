import 'package:flutter/material.dart';

class _WalletReturns extends ChangeNotifier {
  void dispatch() => notifyListeners();
}

/// Keeps wallet callbacks on the existing PID route instead of stacking reviews.
class PidVerificationNavigation extends NavigatorObserver {
  static const routeName = '/pid-verification';
  final List<Route<dynamic>> _routes = [];
  final walletReturns = _WalletReturns();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
  }

  bool resumeExisting() {
    final matches = _routes.where((route) => route.settings.name == routeName);
    if (matches.isEmpty) return false;
    final route = matches.first;
    navigator!.popUntil((candidate) => identical(candidate, route));
    walletReturns.dispatch();
    return true;
  }
}

final pidVerificationNavigation = PidVerificationNavigation();
