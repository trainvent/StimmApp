import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class GroupPictureService {
  GroupPictureService({this._storage});
  final FirebaseStorage? _storage;
  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;

  Future<Uint8List?> pickPicture() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length >= 5 * 1024 * 1024) throw StateError('picture_too_large');
    // Decode and re-encode rather than trusting the filename or MIME type.
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 512,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (data == null || data.lengthInBytes >= 5 * 1024 * 1024) {
          throw StateError('picture_too_large');
        }
        return data.buffer.asUint8List();
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<String> upload(
    String groupId,
    Uint8List bytes, {
    required void Function(double) onProgress,
  }) async {
    final ref = storage.ref('groups/$groupId/profile/${const Uuid().v4()}.png');
    final task = ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final subscription = task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    }, onError: (Object _) {});
    try {
      await task;
      return await ref.getDownloadURL();
    } catch (_) {
      try {
        await ref.delete();
      } catch (_) {}
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> delete(String groupId, String url) async {
    final ref = storage.refFromURL(url);
    // Never delete an unrelated image if a group contains an external URL.
    if (ref.bucket != storage.ref().bucket ||
        !ref.fullPath.startsWith('groups/$groupId/profile/')) {
      return;
    }
    await ref.delete();
  }
}
