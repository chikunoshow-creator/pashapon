// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'groq_service.dart';

class LocalOcrService {
  Future<String> recognizeText(String base64Image) async {
    try {
      final promise = js_util.callMethod(html.window, 'runLocalOcr', [base64Image]);
      final result = await js_util.promiseToFuture(promise);
      return result?.toString() ?? '';
    } catch (e) {
      throw Exception('ローカル文字認識に失敗しました: $e');
    }
  }

  Future<GroqParsedResult> parseReceipt(String base64Image) async {
    final rawText = await recognizeText(base64Image);

    final date = _extractDate(rawText);
    final amount = _extractAmount(rawText);
    final store = _extractStore(rawText);

    return GroqParsedResult(
      isReceipt: true,
      date: date,
      store: store,
      amount: amount,
      reason: 'LocalOCR',
    );
  }

  String _extractDate(String text) {
    final regex = RegExp(r'(\d{4})[./年\-](\d{1,2})[./月\-](\d{1,2})');
    final match = regex.firstMatch(text);
    if (match != null) {
      final y = match.group(1)!;
      final m = match.group(2)!.padLeft(2, '0');
      final d = match.group(3)!.padLeft(2, '0');
      return '$y-$m-$d';
    }
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// ★【マツキヨ問題対策】ポイント・クーポン・お預かり行を完全除外して金額抽出
  int _extractAmount(String text) {
    final lines = text.split('\n');
    int maxAmount = 0;

    // 採用優先キーワード（合計金額らしき行）
    final targetKeywords = ['合計', '小計', 'お買上計', '税込', '支払', '売上計', '¥'];
    
    // ★除外ブラックリストキーワード（下部のポイントやクーポン、お釣り等を遮断）
    final blacklistKeywords = [
      'ポイント', 'pt', 'ステージ', 'クーポン', '値引券',
      'お預り', 'お預かり', 'お釣', 'お釣り', '残高', 'マネー', '還元'
    ];

    for (final line in lines) {
      // 除外キーワードを含む行は丸ごとスキップ！
      if (blacklistKeywords.any((bkw) => line.contains(bkw))) {
        continue;
      }

      bool hasTargetKeyword = targetKeywords.any((kw) => line.contains(kw));
      final numberMatches = RegExp(r'[\d,]{3,}').allMatches(line);

      for (final match in numberMatches) {
        final cleaned = match.group(0)!.replaceAll(',', '');
        final val = int.tryParse(cleaned) ?? 0;
        if (val > 10 && val < 500000) {
          if (hasTargetKeyword && val > maxAmount) {
            maxAmount = val;
          } else if (val > maxAmount && maxAmount == 0) {
            maxAmount = val;
          }
        }
      }
    }

    return maxAmount;
  }

  String _extractStore(String text) {
    final lines = text.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length >= 2 && !RegExp(r'^[\d\s\-_./\\:=]+$').hasMatch(l))
        .toList();

    if (lines.isNotEmpty) {
      String candidate = lines.first;
      if (candidate.length > 20) candidate = candidate.substring(0, 20);
      return candidate;
    }
    return '不明な店舗';
  }
}