class AppConstants {
  // アプリ基本情報
  static const String appName = 'パシャぽん';
  static const String appTagline = '撮って、まとめて、サクッと共有';

  // Groq API 設定
  static const String groqApiEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  
  // ★最新のGroq公式推奨Visionモデル（旧llama-3.2-11bは廃止済み）
  static const String defaultGroqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // ストレージの保存キー
  static const String prefKeySettings = 'pashapon_settings';
  static const String prefKeyReceipts = 'pashapon_receipts';
  static const String prefKeyErrorLogs = 'pashapon_error_logs';

  // 画像圧縮設定
  static const int imageMaxDimension = 900;
  static const int imageCompressQuality = 75;

  // Groqに送るシステムプロンプト
  static const String receiptAnalysisPrompt = '''
あなたは優秀なレシート読取AIです。
提供されたレシート画像から、次の3つの項目のみを抽出し、指定のJSON形式で出力してください。

1. "date": 購入日。フォーマットは必ず "YYYY-MM-DD" としてください。年が記載されていない場合は今年と推測してください。不明な場合は今日の文字列を入れてください。
2. "store": 店舗名またはサービス名（文字列）。できるだけ正確に短く抽出してください。
3. "amount": 支払合計金額（税込）。数値（整数）のみで出力してください。記号（¥や円、カンマ）は含めないでください。

【出力制約】
・Markdownのコードブロックや余計な解説は一切含めず、純粋なJSONオブジェクトのみを出力してください。
・フォーマット例:
{"date": "2026-11-12", "store": "スーパーABC", "amount": 2580}
''';
}