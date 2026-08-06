import 'package:flutter_riverpod/flutter_riverpod.dart';

final profilePictureUrlProvider =
    NotifierProvider<ProfilePictureUrlController, String?>(
      ProfilePictureUrlController.new,
    );

class ProfilePictureUrlController extends Notifier<String?> {
  @override
  String? build() => null;

  void setUrl(String? url) {
    state = url;
  }

  void setUrlIfUnchanged({required String? expected, required String? url}) {
    if (state != expected) return;
    state = url;
  }

  void clear() {
    state = null;
  }
}
