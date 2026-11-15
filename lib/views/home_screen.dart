import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../models/receipt_item.dart';
import '../providers/receipt_provider.dart';
import '../providers/settings_provider.dart';
import '../services/groq_service.dart';
import '../services/image_service.dart';
import '../services/local_ocr_service.dart';
import 'camera/silent_camera_screen.dart';
import 'settings/settings_dialog.dart';
import 'widgets/error_log_dialog.dart';
import 'widgets/receipt_card.dart';
import 'widgets/receipt_edit_modal.dart';
import 'widgets/summary_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImageService _imageService = ImageService();
  final GroqService _groqService = GroqService();
  final LocalOcrService _localOcrService = LocalOcrService();

  bool _isLoading = false;
  String _loadingMessage = '';
  bool _hasCheckedOnboarding = false;
  bool _isDailyGrouping = false; // ★明細順 vs 日別まとめ 切り替え

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(receiptListProvider);
    final isInitialized = ref.watch(settingsInitializedProvider);
    final settings = ref.watch(settingsProvider);

    if (isInitialized && !_hasCheckedOnboarding) {
      _hasCheckedOnboarding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkFirstTimeOnboarding(settings.isConfigured);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ★【上部のかすれ完全解消＆プロデューサー案ヘッダー】
          // 画面の最上端（時計の裏）まで完全にベタ塗りで届くコンテナ構造
          Container(
            color: const Color(0xFFFFF8F2), // プロデューサーのスクショの温かみのあるカラー
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFFFEBDD), width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    // アプリアイコン ＆ タイトル
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFDEC7)),
                      ),
                      child: const Icon(Icons.receipt_long, color: Color(0xFFE07A5F), size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFFD35400),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    // ★厳選した3ボタンのみ！
                    IconButton(
                      icon: const Icon(Icons.share, color: Color(0xFFD35400), size: 20),
                      tooltip: '共有',
                      visualDensity: VisualDensity.compact,
                      onPressed: _shareReceipts,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Color(0xFFD35400), size: 20),
                      tooltip: '一括リセット',
                      visualDensity: VisualDensity.compact,
                      onPressed: receipts.isEmpty ? null : _confirmClearAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFFD35400), size: 20),
                      tooltip: '設定',
                      visualDensity: VisualDensity.compact,
                      onPressed: _showSettings,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // サマリーエリア（支出サマリー、モードバッジ、合計カード、切り替えタブ）
          SummaryHeader(
            isAiMode: settings.isAiMode,
            onModeTap: () => _showModeExplanation(settings.isAiMode),
            isDailyGrouping: _isDailyGrouping,
            onGroupingChanged: (val) => setState(() => _isDailyGrouping = val),
          ),

          // メインリストエリア
          Expanded(
            child: Stack(
              children: [
                receipts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.teal.shade200),
                              const SizedBox(height: 16),
                              const Text(
                                '財布にレシート溜まってませんか？',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'いまパシャッと撮っておくだけで、\n後からの家計簿入力が爆速でラクになりますよ！',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '👇 下のボタンから撮影・選択してください',
                                style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _isDailyGrouping
                        ? _buildDailyGroupedList(receipts)
                        : _buildDetailList(receipts),

                if (_isLoading)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(_loadingMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _processGalleryImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('写真選択'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _openSilentCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('レシート撮影'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: '手入力',
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ReceiptEditModal(
                      onSave: (date, store, amount) {
                        ref.read(receiptListProvider.notifier).addReceipt(
                              date: date,
                              store: store,
                              amount: amount,
                            );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 通常の明細フラット一覧
  Widget _buildDetailList(List<ReceiptItem> receipts) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        final item = receipts[index];
        return ReceiptCard(
          item: item,
          onUpdate: (updated) => ref.read(receiptListProvider.notifier).updateReceipt(updated),
          onDelete: () => ref.read(receiptListProvider.notifier).deleteReceipt(item.id),
        );
      },
    );
  }

  /// ★【日別まとめモード】日付ごとにセクション分け＆小計を表示する一覧
  Widget _buildDailyGroupedList(List<ReceiptItem> receipts) {
    // 日付ごとにグルーピング
    final Map<String, List<ReceiptItem>> grouped = {};
    for (final item in receipts) {
      grouped.putIfAbsent(item.date, () => []).add(item);
    }

    final dates = grouped.keys.toList();
    final currencyFormatter = NumberFormat('#,###', 'ja_JP');

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: dates.length,
      itemBuilder: (context, dIndex) {
        final date = dates[dIndex];
        final dayItems = grouped[date]!;
        final dayTotal = dayItems.fold(0, (sum, i) => sum + i.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付ヘッダー ＆ その日の小計
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '日計: ¥${currencyFormatter.format(dayTotal)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // その日のレシート一覧
            ...dayItems.map((item) => ReceiptCard(
                  item: item,
                  onUpdate: (updated) => ref.read(receiptListProvider.notifier).updateReceipt(updated),
                  onDelete: () => ref.read(receiptListProvider.notifier).deleteReceipt(item.id),
                )),
          ],
        );
      },
    );
  }

  Future<void> _checkFirstTimeOnboarding(bool isConfigured) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(AppConstants.prefKeyHasSeenOnboarding) ?? false;
    if (hasSeen || isConfigured) return;

    await prefs.setBool(AppConstants.prefKeyHasSeenOnboarding, true);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.teal),
            SizedBox(width: 8),
            Text('ようこそパシャぽんへ！', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'レシートの「いつ・どこで・いくら」をパシャッとまとめる家計簿サポートアプリです。\n\nお好みの始め方を選んでください：',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('🌿 まずは設定なしで試す'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.rocket_launch, size: 16),
            label: const Text('🚀 AI高精度モード（推奨）'),
            onPressed: () {
              Navigator.pop(ctx);
              _showSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showModeExplanation(bool isAiMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAiMode ? '🚀 AI高精度モード（稼働中）' : '🌿 標準モード（稼働中）'),
        content: Text(
          isAiMode
              ? 'Groqの超高速Vision AIが、くしゃくしゃのレシートや手書き領収書も高精度に判読します！'
              : '端末内部の文字認識（ローカルOCR）で動作しています。外部通信ゼロで安全ですが、複雑なレシートは「不明」になることがあります。\n\n💡 無料のAIキーを設定すると「AI高精度モード」に切り替わります！',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          if (!isAiMode)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showSettings();
              },
              child: const Text('AIキーを設定する'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる')),
        ],
      ),
    );
  }

  Future<void> _processGalleryImage() async {
    final bytes = await _imageService.pickImage(ImageSource.gallery);
    if (bytes == null) return;
    await _analyzeBytes(bytes);
  }

  Future<void> _openSilentCamera() async {
    final Uint8List? capturedBytes = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SilentCameraScreen()),
    );
    if (capturedBytes == null) return;
    await _analyzeBytes(capturedBytes);
  }

  Future<void> _analyzeBytes(Uint8List rawBytes) async {
    final settings = ref.read(settingsProvider);

    final isLikely = _imageService.isLikelyDocument(rawBytes);
    if (!isLikely) {
      _showNotReceiptDialog();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _loadingMessage = '画像を圧縮中...';
      });

      final base64Image = await _imageService.compressAndEncodeBase64(rawBytes);

      GroqParsedResult result;

      if (settings.isAiMode) {
        setState(() => _loadingMessage = 'AI解析中（Groq）...');
        result = await _groqService.analyzeReceipt(
          base64Image: base64Image,
          settings: settings,
        );
      } else {
        setState(() => _loadingMessage = '文字認識中（端末内OCR）...');
        result = await _localOcrService.parseReceipt(base64Image);
      }

      if (!result.isReceipt) {
        _showNotReceiptDialog();
        return;
      }

      await ref.read(receiptListProvider.notifier).addReceipt(
            date: result.date,
            store: result.store,
            amount: result.amount,
            thumbnailBase64: base64Image,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${result.store}」を追加しました！'),
            action: (!settings.isAiMode && (result.store == '不明な店舗' || result.amount == 0))
                ? SnackBarAction(
                    label: 'AIで読む',
                    textColor: Colors.tealAccent,
                    onPressed: _showSettings,
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        String friendlyMessage = 'うまく読み取れませんでした💦\nもう一度パシャッと撮り直してみてね';

        if (errorStr.contains('429') || errorStr.contains('rate limit')) {
          friendlyMessage = 'ただいまAIが混み合っています☕️\n1分ほど置いてから、もう一度試してみてね';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage, style: const TextStyle(fontSize: 13, height: 1.4)),
            backgroundColor: Colors.blueGrey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '詳細',
              textColor: Colors.tealAccent,
              onPressed: _showErrorLogs,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNotReceiptDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('認識できませんでした', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'レシートとして認識できませんでした。\nレシートや領収書を枠内に合わせて撮影してください。\n（※文字のない写真やレシート以外の画像は保存されません）',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(context: context, builder: (_) => const SettingsDialog());
  }

  void _showErrorLogs() {
    showDialog(context: context, builder: (_) => const ErrorLogDialog());
  }

  // ★モードに応じた共有テキスト生成（明細順 or 日別小計つき）
  void _shareReceipts() async {
    final receipts = ref.read(receiptListProvider);
    if (receipts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('共有するレシートがありません')),
      );
      return;
    }

    final total = ref.read(totalAmountProvider);
    final formatter = NumberFormat('#,###', 'ja_JP');
    final buffer = StringBuffer();

    buffer.writeln('📋 【レシート共有】');

    if (_isDailyGrouping) {
      // 日別まとめフォーマット
      final Map<String, List<ReceiptItem>> grouped = {};
      for (final item in receipts) {
        grouped.putIfAbsent(item.date, () => []).add(item);
      }
      for (final entry in grouped.entries) {
        final dayTotal = entry.value.fold(0, (sum, i) => sum + i.amount);
        buffer.writeln('■ ${entry.key}');
        for (final item in entry.value) {
          buffer.writeln('  ・${item.store}：¥${formatter.format(item.amount)}');
        }
        buffer.writeln('  【小計：¥${formatter.format(dayTotal)}】\n');
      }
    } else {
      // シンプル明細フォーマット
      for (final item in receipts) {
        buffer.writeln('・${item.date} ${item.store}：¥${formatter.format(item.amount)}');
      }
    }

    buffer.writeln('--------------------');
    buffer.writeln('合計：${receipts.length}件 ¥${formatter.format(total)}');

    final text = buffer.toString();

    try {
      await Share.share(text, subject: 'レシート一覧');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('クリップボードにコピーしました！そのまま貼り付けられます。')),
        );
      }
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('履歴の一括リセット'),
        // ★【安心容量メッセージ】リセット画面内にスマートに格納
        content: const Text(
          '共有済みのレシートデータとサムネイル画像をすべて消去しますか？\n（APIキー等の設定は保持されます）\n\n💡 定期的にリセットすることで、端末の保存容量を節約し快適にお使いいただけます。',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('戻る')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(receiptListProvider.notifier).clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('履歴をリセットしました')),
              );
            },
            child: const Text('すべて消去'),
          ),
        ],
      ),
    );
  }
}