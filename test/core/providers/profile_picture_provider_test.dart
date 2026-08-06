import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stimmapp/core/providers/profile_picture_provider.dart';

void main() {
  test('stale profile picture loads cannot overwrite a newer upload', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(profilePictureUrlProvider.notifier);
    final valueBeforeLoad = container.read(profilePictureUrlProvider);

    controller.setUrl('fresh-upload-url');
    controller.setUrlIfUnchanged(expected: valueBeforeLoad, url: null);

    expect(container.read(profilePictureUrlProvider), 'fresh-upload-url');
  });

  test('profile picture load applies when state has not changed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(profilePictureUrlProvider.notifier)
        .setUrlIfUnchanged(expected: null, url: 'loaded-url');

    expect(container.read(profilePictureUrlProvider), 'loaded-url');
  });
}
