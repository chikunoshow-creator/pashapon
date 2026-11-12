import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/app_constants.dart';
import '../models/receipt_item.dart';
import '../providers/receipt_provider.dart';
import '../providers/settings_provider.dart';
import '../services/groq_service.dart';
import '../services/image_service.dart';
import 'settings/settings_dialog.dart';
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
  bool _isLoading = false;
  String _loadingMessage = '';

  Future<void> _processImage(ImageSource source) async {
    final settings = ref.read(settingsProvider);
    if (!settings.isConfigured) {
      _showSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先にGroq APIキーを設定してください')),
      );
      return;
    }

    try {
      final bytes = await _imageService.pickImage(source);
      if (bytes == null) return;

      setState(() {
        _isLoading = true;
        _loadingMessage = '画像を圧縮中...';
      });

      final base64Image = await _imageService.compressAndEncodeBase64(bytes);

      setState(() {
        _loadingMessage = 'AI解析中...';
      });

      final result = await _groqService.analyzeReceipt(
        base64Image: base64Image,
        settings: settings,
      );

      await ref.read(receiptListProvider.notifier).addReceipt(
            date: result.date,
            store: result.store,
            amount: result.amount,
            thumbnailBase64: base64Image,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${result.store}」を追加しました！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSettings() {
    showDialog(context: context, builder: (_) => const SettingsDialog());
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
      // Web Share非対応時のフォールバック
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

  @override
  Widget build(BuildContext context) {
    final receipts = ref.watch(receiptListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('レシートがまだありません', style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('下の「撮影」または「画像選択」から読み取れます', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
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
                  onPressed: _isLoading ? null : () => _processImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('写真選択'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : () => _processImage(ImageSource.camera),
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
}