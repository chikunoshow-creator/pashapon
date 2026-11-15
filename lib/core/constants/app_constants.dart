class AppConstants {
  // アプリ基本情報
  static const String appName = 'パシャぽん';
  static const String appVersion = '1.4.0'; // ★v1.4.0に更新！
  static const String appTagline = '撮って、まとめて、サクッと共有';

  // 外部リンク
  static const String contactFormUrl = 'https://forms.gle/tiorxEaCJcU2SgRY9';
  static const String groqConsoleUrl = 'https://console.groq.com';

  // Groq API 設定
  static const String groqApiEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  
  // 推奨Visionモデルの優先度リスト
  static const List<String> fallbackVisionModels = [
    'qwen/qwen3.8-27b',
    'meta-llama/llama-4-scout-17b-16e-instruct',
  ];
  static String get defaultGroqModel => fallbackVisionModels.first;

  // ストレージの保存キー
  static const String prefKeySettings = 'pashapon_settings';
  static const String prefKeyReceipts = 'pashapon_receipts';
  static const String prefKeyErrorLogs = 'pashapon_error_logs';
  static const String prefKeyHasSeenOnboarding = 'pashapon_has_seen_onboarding';

  // 画像圧縮設定
  static const int imageMaxDimension = 900;
  static const int imageCompressQuality = 75;

  // システムプロンプト（マツキヨ問題対策済み）
  static const String receiptAnalysisPrompt = '''
あなたはレシート・領収書を正確に識別・抽出する専門AIです。
提供された画像を解析し、必ず以下のJSONフォーマットのみを出力してください。

【判定基準（重要）】
1. "is_receipt" (boolean):
   ・レシート・領収書・納品書・伝票等の支払い証明書類であれば true。
   ・人物、身体の一部、風景、無関係な物体、または文字が潰れて全く読めない場合は false。

2. "amount" (number): 実際に支払った税込合計金額（整数）。記号不要。
   ※【超重要・除外ルール（誤爆防止）】
   ドラッグストア等のレシート下部に記載されている以下の数値を、絶対に合計金額として抽出しないでください：
   ・「保有ポイント」「獲得ポイント」「今回ポイント」などのポイント数
   ・「ステージアップまであと〇〇円」「ランクアップまで〇〇円」などの目標金額
   ・「次回使える〇〇円引きクーポン」「特別値引〇〇円」などのクーポン額
   ・「お預かり」「現収」「お釣り」「差引金額」
   必ず明細直後の『合計』『お買上計』『税込合計』『クレジット支払額』『請求額』の数値を最優先で採用してください。
   is_receiptがfalseの場合は 0 とする。

3. "date" (string): 購入日 ("YYYY-MM-DD")。不明時は今日の年月日を出力。
4. "store" (string): 店名・発行者名。is_receiptがfalseの場合は "不明" とする。
5. "reason" (string): 判定理由。is_receiptがfalseの場合は具体的な理由。trueの場合は "OK"。

【出力制約】
Markdownコードブロック不要、純粋なJSONオブジェクトのみを出力してください。
{"is_receipt": true, "date": "2026-11-15", "store": "スーパーABC", "amount": 2580, "reason": "OK"}
''';

  // 初心者向けAPIキー取得手順ガイド
  static const String apiKeyGuideText = '''
【Groq 無料AIキーの取得手順（約1分・クレカ不要）】

1. Groq Console（公式サイト）へアクセス
ブラウザで console.groq.com を開き、Googleアカウント等で無料サインアップします。

2. API Keys ページを開く
画面左メニューの「API Keys」をタップします。

3. キーを作成する
「Create API Key」ボタンを押し、好きな名前（例: pashapon）を入力して作成します。

4. キーをコピーして貼り付け
画面に表示された「gsk_...」で始まる文字列をコピーし、パシャぽんの設定画面に貼り付けて「保存」を押せば完了です！
''';

  // 利用規約・プライバシーポリシー全文
  static const String termsAndPrivacyText = '''
【パシャぽん 利用規約・プライバシーポリシー】

本アプリ「パシャぽん」（以下「本サービス」）をご利用いただく前に、以下の規約およびプライバシーポリシーをお読みください。本サービスを利用された場合、本内容に同意したものとみなします。

1. 外部AIサービス（Groq API）へのデータ送信について
・本サービスはレシート・領収書の文字解析を行うため、ユーザーご自身が設定したAPIキーを用いて、外部サービスである「Groq API」のサーバーへ撮影画像データを送信します。
・送信された画像データの取り扱いについては、Groq社の利用規約およびプライバシーポリシーに準拠します。
・クレジットカード番号、マイナンバー、その他機密情報や個人を特定できる情報が記載された書類の撮影・送信は、ユーザーご自身の責任において適切に管理してください。

2. データの保存と管理について
・解析履歴やサムネイル画像は、お使いの端末のブラウザ内（ローカルストレージ）にのみ保存されます。開発者側のサーバーにユーザーのレシート画像や家計データが収集・保存されることは一切ありません。
・ブラウザの履歴・キャッシュ削除や端末の機種変更等により保存データが消失する場合があります。

3. AI解析精度および損害に関する免責事項
・AIによる読み取り結果（店舗名、日付、金額、品目等）の正確性・完全性について、開発者は一切の保証を行わないものとします。必ずユーザーご自身で内容をご確認のうえご利用ください。
・本サービスの利用、または利用できなかったことにより生じた一切の損害について、開発者は責任を負いかねます。また、外部APIの利用に伴う通信費やAPI利用料金（無料枠超過時等）はユーザーご自身の負担となります。

4. アクセス解析ツールの利用について
・本サービスでは、サービス改善および利用状況の把握のために「Googleアナリティクス（GA4）」を利用しています。
・GoogleアナリティクスはCookie等を使用して匿名のトラフィックデータを収集しますが、個人を特定する情報は含まれません。

5. 禁止事項
・本サービスは、レシート・領収書・伝票等の家計管理および記録補助を目的としています。人物の撮影、盗撮、その他公序良俗に反する行為や法令に違反する目的での利用を固く禁じます。違反が判明した場合、利用を制限することがあります。

制定日：2026年11月
''';
}