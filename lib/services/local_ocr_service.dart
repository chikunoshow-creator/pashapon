// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'groq_service.dart';

class LocalOcrService {
  /// ブラウザのTesseract.jsを呼び出し、生テキストを取得
  Future<String> recognizeText(String base64Image) async {
    try {
      final promise = js_util.callMethod(html.window, 'runLocalOcr', [base64Image]);
      final result = await js_util.promiseToFuture(promise);
      return result?.toString() ?? '';
    } catch (e) {
      throw Exception('ローカル文字認識に失敗しました: $e');
    }
  }

  /// 生テキストから「日付・店名・合計金額」をルールベース抽出
  Future<GroqParsedResult> parseReceipt(String base64Image) async {
    final rawText = await recognizeText(base64Image);

    final date = _extractDate(rawText);
    final amount = _extractAmount(rawText);
    final store = _extractStore(rawText);

    return GroqParsedResult(
      isReceipt: true, // 端末内エッジ判定を通過していればレシートとして処理
      date: date,
      store: store,
      amount: amount,
      reason: 'LocalOCR',
    );
  }

  String _extractDate(String text) {
    // YYYY/MM/DD, YYYY-MM-DD, YYYY年MM月DD日 などの正規表現
    final regex = RegExp(r'(\d{4})[./年\-](\d{1,2})[./月\-](\d{1,2})');
    final match = regex.firstMatch(text);
    if (match != null) {
      final y = match.group(1)!;
      final m = match.group(2)!.padLeft(2, '0');
      final d = match.group(3)!.padLeft(2, '0');
      return '$y-$m-$d';
    }
    // 検出できなければ今日の日付
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  int _extractAmount(String text) {
    // 「合計」「計」「税込」「お買上」「¥」付近の数値を探索
    final lines = text.split('\n');
    int maxAmount = 0;

    final targetKeywords = ['合計', '小計', 'お買上', '税込', '支払', '預り', '¥', '円'];

    for (final line in lines) {
      bool hasKeyword = targetKeywords.any((kw) => line.contains(kw));
      // 数字とカンマを抽出
      final numberMatches = RegExp(r'[\d,]{3,}').allMatches(line);

      for (final match in numberMatches) {
        final cleaned = match.group(0)!.replaceAll(',', '');
        final val = int.tryParse(cleaned) ?? 0;
        // 合計欄らしき行にあれば優先、あるいは最もそれらしい金額（10円〜50万円）
        if (val > 10 && val < 500000) {
          if (hasKeyword && val > maxAmount) {
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

    // 1行目〜3行目の中から店名らしき最初のテキストを採用
    if (lines.isNotEmpty) {
      String candidate = lines.first;
      if (candidate.length > 20) candidate = candidate.substring(0, 20);
      return candidate;
    }
    return '不明な店舗';
  }
}