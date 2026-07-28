import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/functions/google_account_links.dart';

void main() {
  group('googleProfileUri', () {
    test('targets the stable Google profile endpoint', () {
      expect(
        googleProfileUri(null),
        Uri.parse('https://myaccount.google.com/profile'),
      );
    });

    test('adds the connected email as an account hint', () {
      final uri = googleProfileUri(' user+test@gmail.com ');

      expect(uri.path, '/profile');
      expect(uri.queryParameters['authuser'], 'user+test@gmail.com');
    });
  });
}
