import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/app/pages/main/groups/member_groups_page.dart';
import 'package:stimmapp/core/constants/internal_constants.dart';
import 'package:stimmapp/core/data/models/user_profile.dart';

void main() {
  test('forced-Pro Auth email can create an additional group', () {
    expect(
      groupCreationRequiresPro(
        createdCount: 1,
        profile: const UserProfile(uid: 'owner-1', isPro: false),
        authenticatedEmail: IConst.adminEmail,
      ),
      isFalse,
    );
  });

  test('basic users still need Pro for an additional group', () {
    expect(
      groupCreationRequiresPro(
        createdCount: 1,
        profile: const UserProfile(
          uid: 'basic-1',
          email: 'basic@example.com',
          isPro: false,
        ),
        authenticatedEmail: 'basic@example.com',
      ),
      isTrue,
    );
  });
}
