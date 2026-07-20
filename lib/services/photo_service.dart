import 'dart:io';
import 'dart:typed_data';

import 'package:exif_reader/exif_reader.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  PhotoService._();

  /// Copies a photo from [sourcePath] into a per-app "catches" directory
  /// so the file survives gallery cleanup. Returns the permanent path.
  /// EXIF metadata (including GPS) is stripped before saving.
  static Future<String> savePhotoToAppDir(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final catchesDir = Directory(p.join(dir.path, 'catches'));
    if (!await catchesDir.exists()) {
      await catchesDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath);
    final destName = 'catch_${DateTime.now().millisecondsSinceEpoch}$ext';
    final destPath = p.join(catchesDir.path, destName);

    await _stripExifAndSave(sourcePath, destPath);
    return destPath;
  }

  /// Reads the image from [sourcePath], strips all EXIF metadata (including GPS),
  /// and writes a clean copy to [destPath].
  /// Preserves image orientation by applying EXIF rotation before stripping.
  static Future<void> _stripExifAndSave(String sourcePath, String destPath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      // Fallback: copy original if decode fails
      await File(sourcePath).copy(destPath);
      return;
    }

    // Read EXIF orientation BEFORE we strip metadata
    int orientation = 1;
    try {
      final exif = await readExifFromBytes(bytes);
      final tag = exif.tags['Image Orientation'];
      final val = tag?.values.firstAsInt();
      if (val != null) {
        orientation = val;
      }
    } catch (_) {
      // Ignore EXIF read errors
    }

    // Apply orientation transform to pixel data so we can strip EXIF cleanly
    img.Image orientedImage = image;
    switch (orientation) {
      case 2:
        orientedImage = img.flipHorizontal(image);
        break;
      case 3:
        orientedImage = img.copyRotate(image, angle: 180);
        break;
      case 4:
        orientedImage = img.flipVertical(image);
        break;
      case 5:
        orientedImage = img.flipHorizontal(img.copyRotate(image, angle: 90));
        break;
      case 6:
        orientedImage = img.copyRotate(image, angle: 90);
        break;
      case 7:
        orientedImage = img.flipHorizontal(img.copyRotate(image, angle: 270));
        break;
      case 8:
        orientedImage = img.copyRotate(image, angle: 270);
        break;
      default:
        orientedImage = image;
    }

    // Resize to cap the longest side at 1080px to reduce memory pressure
    const maxDim = 1080;
    if (orientedImage.width > maxDim || orientedImage.height > maxDim) {
      orientedImage = orientedImage.width >= orientedImage.height
          ? img.copyResize(orientedImage, width: maxDim)
          : img.copyResize(orientedImage, height: maxDim);
    }

    // Encode without any metadata
    final ext = p.extension(destPath).toLowerCase();
    Uint8List encodedBytes;
    if (ext == '.png') {
      encodedBytes = Uint8List.fromList(img.encodePng(orientedImage));
    } else {
      // Default to JPEG at 90% quality
      encodedBytes = Uint8List.fromList(img.encodeJpg(orientedImage, quality: 90));
    }

    await File(destPath).writeAsBytes(encodedBytes);
  }
}
