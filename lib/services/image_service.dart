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

  /// ★【第1の防壁】端末内・送信前の「文字（エッジ）チラつき判定」
  /// クラウド（Groq）に送る前に、書類・レシートの特徴（文字による明暗差）があるかを純Dartで高速判定
  bool isLikelyDocument(Uint8List rawBytes) {
    try {
      final img.Image? decoded = img.decodeImage(rawBytes);
      if (decoded == null) return false;

      // 計算負荷を下げるため、幅120px程度に超縮小してスキャン
      final thumbnail = img.copyResize(decoded, width: 120);

      int edgeCount = 0;
      double totalLuminance = 0;
      final int totalPixels = thumbnail.width * thumbnail.height;

      // 輝度マップを走査し、隣接ピクセルとの明暗差（文字のエッジ）を計算
      for (int y = 0; y < thumbnail.height - 1; y++) {
        for (int x = 0; x < thumbnail.width - 1; x++) {
          final pCurrent = thumbnail.getPixel(x, y);
          final pRight = thumbnail.getPixel(x + 1, y);
          final pBottom = thumbnail.getPixel(x, y + 1);

          // 輝度計算 (0.299R + 0.587G + 0.114B)
          final lumCurrent = 0.299 * pCurrent.r + 0.587 * pCurrent.g + 0.114 * pCurrent.b;
          final lumRight = 0.299 * pRight.r + 0.587 * pRight.g + 0.114 * pRight.b;
          final lumBottom = 0.299 * pBottom.r + 0.587 * pBottom.g + 0.114 * pBottom.b;

          totalLuminance += lumCurrent;

          // 隣り合うピクセル間で急激な明暗差（文字の輪郭）があるか
          final diffH = (lumCurrent - lumRight).abs();
          final diffV = (lumCurrent - lumBottom).abs();

          if (diffH > 35 || diffV > 35) {
            edgeCount++;
          }
        }
      }

      final avgLuminance = totalLuminance / totalPixels;
      final edgeRatio = edgeCount / totalPixels;

      // 【判定基準】
      // 1. 極端に暗い画像（真っ黒な暗闇など）は除外 (avgLuminance > 50)
      // 2. 文字のエッジ（明暗の激しい境界）が一定以上存在するか (edgeRatio >= 0.04)
      // （※滑らかな布地、肌、風景、一様な壁などはエッジ比率が極端に低いためここで弾かれます）
      if (avgLuminance < 50 || edgeRatio < 0.04) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
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