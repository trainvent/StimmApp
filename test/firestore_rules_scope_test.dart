import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore rules recognize normalized country-union scopes', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains("'countryUnion'"));
    expect(rules, contains("data.scopeUnionCode in ['EU', 'UN']"));
    expect(rules, contains("data.keys().hasAll(['scopeType', 'scopeKey'])"));
  });

  test('German PID profiles may omit a state or region', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(
      rules,
      contains(
        "data.state == null ||\n"
        "           data.state == '' ||\n"
        '           hasStateValue(data)',
      ),
    );
    expect(
      rules,
      contains('because the requested German PID address has no region claim'),
    );
  });
}
