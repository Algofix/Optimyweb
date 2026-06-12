import 'dart:typed_data';

/// An image chosen by the user, ready to be uploaded.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.name,
    required this.contentType,
  });

  final Uint8List bytes;
  final String name;
  final String contentType;
}
