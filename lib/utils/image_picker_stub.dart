import 'picked_image.dart';

/// Fallback for non-web platforms. Picking an image from native storage needs
/// a platform plugin (e.g. `image_picker`), which isn't wired up here, so this
/// returns `null`.
Future<PickedImage?> pickImage() async => null;
