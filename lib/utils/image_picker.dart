import 'image_picker_stub.dart'
    if (dart.library.js_interop) 'image_picker_web.dart' as impl;
import 'picked_image.dart';

export 'picked_image.dart';

/// Prompts the user to choose an image file. Returns the selected image, or
/// `null` if the user cancelled (or the platform can't pick files).
Future<PickedImage?> pickImage() => impl.pickImage();
