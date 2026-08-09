import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore rules recognize normalized country-union scopes', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains("'countryUnion'"));
    expect(rules, contains("data.scopeUnionCode in ['EU', 'UN']"));
    expect(rules, contains("data.keys().hasAll(['scopeType', 'scopeKey'])"));
  });
}
