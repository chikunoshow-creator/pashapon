import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/error_log.dart';
import 'storage_service.dart';

class GroqParsedResult {
  final bool isReceipt;
  final String date;
  final String store;
  final int amount;
  final String reason;

  GroqParsedResult({
    required this.isReceipt,
    required this.date,
    required this.store,
    required this.amount,
    required this.reason,
  });
}

class GroqService {
  final StorageService _storage = StorageService();

  /// ★多段自動フォールバック付き解析
  Future<GroqParsedResult> analyzeReceipt({
    required String base64Image,
    required AppSettings settings,
  }) async {
    if (!settings.isConfigured) {
      const msg = 'Groq APIキーが設定されていません。';
      await _recordLog('ConfigError', msg, null);
      throw Exception(msg);
    }

    // 優先度リスト順に試行（第1候補 ➔ 第2候補）
    dynamic lastError;
    for (final model in AppConstants.fallbackVisionModels) {
      try {
        return await _executeRequest(
          base64Image: base64Image,
          apiKey: settings.apiKey,
          modelName: model,
        );
      } catch (e) {
        lastError = e;
        // モデル廃止・見つからないエラーの場合は次候補へ自動フォールバック
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('model_decommissioned') ||
            errStr.contains('not_found') ||
            errStr.contains('404')) {
          await _recordLog('ModelFallback', 'モデル $model から次候補へ自動切替します', e.toString());
          continue; // 次のモデルでリトライ！
        }
        // レートリミット等のモデル以外のエラーはそのまま再スロー
        rethrow;
      }
    }

    throw lastError ?? Exception('すべてのAIモデルでの解析に失敗しました。');
  }

  Future<GroqParsedResult> _executeRequest({
    required String base64Image,
    required String apiKey,
    required String modelName,
  }) async {
    final uri = Uri.parse(AppConstants.groqApiEndpoint);
    final headers = {
      'Authorization': 'Bearer ${apiKey.trim()}',
      'Content-Type': 'application/json',
    };

    final imageUrl = 'data:image/jpeg;base64,$base64Image';

    final body = jsonEncode({
      'model': modelName,
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
      'max_tokens': 500, // トークン制限対策済み
    });

    final response = await http.post(uri, headers: headers, body: body);

    if (response.statusCode != 200) {
      final errorBody = utf8.decode(response.bodyBytes);
      final logMessage = 'Groq APIエラー (HTTP ${response.statusCode})';
      await _recordLog('ApiError', logMessage, 'Model: $modelName\nResponse: $errorBody');
      throw Exception('$logMessage: $errorBody');
    }

    final Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.bodyBytes));
    final String? rawContent = responseData['choices']?[0]?['message']?['content'];

    if (rawContent == null || rawContent.isEmpty) {
      const msg = 'Groq APIから空の応答が返されました。';
      await _recordLog('EmptyResponse', msg, responseData.toString());
      throw Exception(msg);
    }

    try {
      return _parseJsonResponse(rawContent);
    } catch (e) {
      await _recordLog('ParseError', 'JSON解析失敗', 'Raw content: $rawContent\nError: $e');
      rethrow;
    }
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

    final Map<String, dynamic> jsonMap = jsonDecode(cleaned);
    final isReceipt = jsonMap['is_receipt'] == true;
    final date = jsonMap['date']?.toString() ?? '';
    final store = jsonMap['store']?.toString() ?? '不明な店舗';
    final amount = (jsonMap['amount'] as num?)?.toInt() ?? 0;
    final reason = jsonMap['reason']?.toString() ?? 'OK';

    return GroqParsedResult(
      isReceipt: isReceipt,
      date: date.isNotEmpty ? date : DateTime.now().toIso8601String().substring(0, 10),
      store: store,
      amount: amount,
      reason: reason,
    );
  }

  Future<void> _recordLog(String type, String message, String? details) async {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    await _storage.addErrorLog(ErrorLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: now,
      errorType: type,
      message: message,
      details: details,
    ));
  }
}