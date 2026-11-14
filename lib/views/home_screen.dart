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

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(receiptListProvider);
    final isInitialized = ref.watch(settingsInitializedProvider);
    final settings = ref.watch(settingsProvider);

    // ★初回起動時オンボーディング（選べる2択ダイアログ）
    if (isInitialized && !_hasCheckedOnboarding) {
      _hasCheckedOnboarding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkFirstTimeOnboarding(settings.isConfigured);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            // ★【ステータスバッジ】現在の動作モードを可視化
            GestureableBadge(
              isAiMode: settings.isAiMode,
              onTap: () => _showModeExplanation(settings.isAiMode),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'エラーログ',
            onPressed: _showErrorLogs,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'LINE等へ共有',
            onPressed: _shareReceipts,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '一括消去',
            onPressed: receipts.isEmpty ? null : _confirmClearAll,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SummaryHeader(),
              Expanded(
                child: receipts.isEmpty
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
                    : ListView.builder(
                        itemCount: receipts.length,
                        itemBuilder: (context, index) {
                          final item = receipts[index];
                          return ReceiptCard(
                            item: item,
                            onUpdate: (updated) => ref.read(receiptListProvider.notifier).updateReceipt(updated),
                            onDelete: () => ref.read(receiptListProvider.notifier).deleteReceipt(item.id),
                          );
                        },
                      ),
              ),
            ],
          ),
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

  /// 初回起動時の2択オンボーディング判定
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

    // 端末内判定（文字のない画像は外部送信を遮断）
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

      // ★【動作振り分け】AIモード or ローカルOCRモード
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
    for (final item in receipts) {
      buffer.writeln('・${item.date} ${item.store}：¥${formatter.format(item.amount)}');
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
          const SnackBar(content: Text('クリップボードにコピーしました！そのままLINEに貼り付けられます。')),
        );
      }
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('履歴の一括リセット'),
        content: const Text('共有済みのレシートデータとサムネイル画像をすべて消去しますか？\n（APIキー等の設定は保持されます）'),
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

/// 動作モードを可視化する可愛いバッジ
class GestureableBadge extends StatelessWidget {
  final bool isAiMode;
  final VoidCallback onTap;

  const GestureableBadge({super.key, required this.isAiMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isAiMode ? Colors.purple.shade50 : Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAiMode ? Colors.purple.shade300 : Colors.teal.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAiMode ? '🚀 AI高精度' : '🌿 標準',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isAiMode ? Colors.purple.shade800 : Colors.teal.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}