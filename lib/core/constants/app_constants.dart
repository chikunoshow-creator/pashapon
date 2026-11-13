class AppConstants {
  // アプリ基本情報
  static const String appName = 'パシャぽん';
  static const String appVersion = '1.2.0'; // ★v1.2.0に更新
  static const String appTagline = '撮って、まとめて、サクッと共有';

  // 外部リンク
  static const String contactFormUrl = 'https://forms.gle/tiorxEaCJcU2SgRY9';

  // Groq API 設定
  static const String groqApiEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String defaultGroqModel = 'qwen/qwen3.8-27b';

  // ストレージの保存キー
  static const String prefKeySettings = 'pashapon_settings';
  static const String prefKeyReceipts = 'pashapon_receipts';
  static const String prefKeyErrorLogs = 'pashapon_error_logs';

  // 画像圧縮設定
  static const int imageMaxDimension = 900;
  static const int imageCompressQuality = 75;

  // システムプロンプト（厳格なレシート判定）
  static const String receiptAnalysisPrompt = '''
あなたはレシート・領収書を正確に識別・抽出する専門AIです。
提供された画像を解析し、必ず以下のJSONフォーマットのみを出力してください。

【判定基準（重要）】
1. "is_receipt" (boolean):
   ・trueとする場合：
     多少のシワ、折れ目、影、ピンボケ、斜め撮影、手書きの領収書・納品書・伝票であっても、
     買い物の記録（品目・店舗・金額のいずれか）が確認できる書類であれば必ず true にしてください。
   ・falseとする場合：
     人物、顔、身体の一部、風景、食事そのもの、家具、衣服など、
     「明らかにレシート・領収書・伝票の類ではない画像」は必ず false にしてください。
     また、文字が完全に潰れていて店名・日付・金額が一切判読できない場合も false にしてください。

2. "date" (string): 購入日 ("YYYY-MM-DD")。不明時は今日の年月日を出力。
3. "store" (string): 店名・発行者名。is_receiptがfalseの場合は "不明" とする。
4. "amount" (number): 税込合計金額（整数）。is_receiptがfalseの場合は 0 とする。
5. "reason" (string): 判定理由。is_receiptがfalseの場合は具体的な理由（例: "レシート以外の被写体です"）。trueの場合は "OK"。

【出力制約】
Markdownコードブロックや余計な解説は一切含めず、純粋なJSONオブジェクトのみを出力してください。

【出力例】
{"is_receipt": true, "date": "2026-11-12", "store": "スーパーABC", "amount": 2580, "reason": "OK"}
{"is_receipt": false, "date": "", "store": "", "amount": 0, "reason": "レシート以外の被写体です"}
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