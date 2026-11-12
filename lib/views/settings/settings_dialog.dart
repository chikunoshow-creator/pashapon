// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../widgets/error_log_dialog.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _modelController = TextEditingController(
      text: settings.modelName.isNotEmpty ? settings.modelName : AppConstants.defaultGroqModel,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  /// ★PWAの強固なキャッシュストレージ＆Service Workerを完全破棄してリロード
  Future<void> _forceUpdateApp() async {
    setState(() => _isReloading = true);

    try {
      // 1. Service Workerの登録解除
      final sw = html.window.navigator.serviceWorker;
      if (sw != null) {
        final registrations = await sw.getRegistrations();
        for (final reg in registrations) {
          await reg.unregister();
        }
      }

      // 2. ブラウザのキャッシュストレージ（CacheStorage）を全削除
      final cacheStorage = html.window.caches;
      if (cacheStorage != null) {
        final keys = await cacheStorage.keys();
        for (final key in keys) {
          await cacheStorage.delete(key);
        }
      }
    } catch (_) {
      // 非対応ブラウザ対策
    }

    // 3. タイムスタンプクエリを付与してキャッシュをバイパスして強制再読み込み
    final currentUri = Uri.parse(html.window.location.href);
    final newUri = currentUri.replace(
      queryParameters: {
        ...currentUri.queryParameters,
        'v': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    html.window.location.href = newUri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('設定'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Groq Console で取得した無料APIキー（gsk_...）を入力してください。端末内のみに安全に保存されます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Groq API Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'モデル名',
                border: OutlineInputBorder(),
                helperText: '推奨: ${AppConstants.defaultGroqModel}',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.bug_report, size: 18),
              label: const Text('エラーログを確認する'),
              onPressed: () {
                showDialog(context: context, builder: (_) => const ErrorLogDialog());
              },
            ),
            const Divider(height: 32),

            // ★バージョン表記 ＆ 強制キャッシュ破棄エリア
            Center(
              child: Column(
                children: [
                  Text(
                    'アプリバージョン: v${AppConstants.appVersion}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
                    icon: _isReloading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_isReloading ? '更新中...' : 'キャッシュを削除して最新版に更新'),
                    onPressed: _isReloading ? null : _forceUpdateApp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () async {
            await ref.read(settingsProvider.notifier).updateSettings(
                  apiKey: _apiKeyController.text.trim(),
                  modelName: _modelController.text.trim(),
                );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}