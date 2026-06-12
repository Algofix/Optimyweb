import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thin wrapper around Firebase Storage for project assets.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads [bytes] as the cover image for [projectId] and returns the
  /// public download URL. Stored at `projects/{projectId}/cover`.
  Future<String> uploadProjectCover(
    String projectId,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref('projects/$projectId/cover');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
