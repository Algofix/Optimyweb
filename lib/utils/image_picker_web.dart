import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'picked_image.dart';

/// Opens the browser file chooser (images only) and reads the chosen file's
/// bytes via the DOM `File.arrayBuffer()` API.
Future<PickedImage?> pickImage() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';

  final completer = Completer<web.File?>();
  input.onchange = ((web.Event _) {
    final files = input.files;
    completer.complete(
      (files != null && files.length > 0) ? files.item(0) : null,
    );
  }).toJS;

  input.click();
  final file = await completer.future;
  if (file == null) return null;

  final buffer = (await file.arrayBuffer().toDart);
  final bytes = buffer.toDart.asUint8List();
  final type = file.type;
  return PickedImage(
    bytes: bytes,
    name: file.name,
    contentType: type.isEmpty ? 'application/octet-stream' : type,
  );
}
