import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/app_settings.dart';

class GroqParsedResult {
  final String date;
  final String store;
  final int amount;

  GroqParsedResult({
    required this.date,
    required this.store,
    required this.amount,
  });
}

class GroqService {
  Future<GroqParsedResult> analyzeReceipt({
    required String base64Image,
    required AppSettings settings,
  }) async {
    if (!settings.isConfigured) {
      throw Exception('Groq APIキーが設定されていません。右上の歯車アイコンからキーを入力してください。');
    }

    final uri = Uri.parse(AppConstants.groqApiEndpoint);
    final headers = {
      'Authorization': 'Bearer ${settings.apiKey.trim()}',
      'Content-Type': 'application/json',
    };

    final imageUrl = 'data:image/jpeg;base64,$base64Image';

    final body = jsonEncode({
      'model': settings.modelName.trim().isNotEmpty
          ? settings.modelName.trim()
          : AppConstants.defaultGroqModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': AppConstants.receiptAnalysisPrompt},
            {'type': 'image_url', 'image_url': {'url': imageUrl}},
          ],
        }
      ],
      'temperature': 0.1,
    });

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode != 200) {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('Groq APIエラー (${response.statusCode}): $errorBody');
    }

    final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
    final String? rawContent = responseData['choices']?[0]?['message']?['content'];

    if (rawContent == null || rawContent.isEmpty) {
      throw Exception('Groq APIから空の応答が返されました。');
    }

    return _parseJsonResponse(rawContent);
  }

  GroqParsedResult _parseJsonResponse(String rawContent) {
    String cleaned = rawContent.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replaceFirst('```json', '');
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst('```', '');
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(cleaned);
      final date = jsonMap['date']?.toString() ?? '';
      final store = jsonMap['store']?.toString() ?? '不明な店舗';
      final amount = (jsonMap['amount'] as num?)?.toInt() ?? 0;

      return GroqParsedResult(
        date: date.isNotEmpty ? date : DateTime.now().toIso8601String().substring(0, 10),
        store: store,
        amount: amount,
      );
    } catch (_) {
      throw Exception('AIの応答をJSONとして解釈できませんでした: $cleaned');
    }
  }
}