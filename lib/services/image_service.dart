import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Capture image from camera with error handling
  Future<File?> captureImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxHeight: 1800,
        maxWidth: 1800,
        imageQuality: 85, // Good balance of quality and size
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) {
        return null;
      }

      final File file = File(pickedFile.path);

      // Verify file exists
      if (await file.exists()) {
        return file;
      } else {
        throw Exception('Captured image file not found');
      }
    } catch (e) {
      throw Exception('Camera capture failed: ${e.toString()}');
    }
  }

  /// Select image from gallery with error handling
  Future<File?> selectFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 1800,
        maxWidth: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      final File file = File(pickedFile.path);

      // Verify file exists
      if (await file.exists()) {
        return file;
      } else {
        throw Exception('Selected image file not found');
      }
    } catch (e) {
      throw Exception('Gallery selection failed: ${e.toString()}');
    }
  }
}
