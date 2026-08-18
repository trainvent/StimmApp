import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/constants/app_limits.dart';

void main() {
  test('Firestore username minimum mirrors AppLimits', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(AppLimits.minUsernameLength, 6);
    expect(rules, contains('request.resource.data.displayName.size() >= 6'));
    expect(rules, contains('data.displayName.size() >= 6'));
  });
}
