import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    return await file.readAsBytes();
  }

  Future<String> compressAndEncodeBase64(Uint8List rawBytes) async {
    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw Exception('画像データの読み込みに失敗しました。');
    }

    img.Image resized = decoded;
    if (decoded.width > AppConstants.imageMaxDimension ||
        decoded.height > AppConstants.imageMaxDimension) {
      if (decoded.width > decoded.height) {
        resized = img.copyResize(decoded, width: AppConstants.imageMaxDimension);
      } else {
        resized = img.copyResize(decoded, height: AppConstants.imageMaxDimension);
      }
    }

    final List<int> compressedJpg = img.encodeJpg(
      resized,
      quality: AppConstants.imageCompressQuality,
    );

    return base64Encode(compressedJpg);
  }
}