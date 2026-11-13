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
  bool _obscureApiKey = true; // パスワードマスク表示切替
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

  Future<void> _forceUpdateApp() async {
    setState(() => _isReloading = true);
    try {
      final sw = html.window.navigator.serviceWorker;
      if (sw != null) {
        final registrations = await sw.getRegistrations();
        for (final reg in registrations) {
          await reg.unregister();
        }
      }
      final cacheStorage = html.window.caches;
      if (cacheStorage != null) {
        final keys = await cacheStorage.keys();
        for (final key in keys) {
          await cacheStorage.delete(key);
        }
      }
    } catch (_) {}

    final currentUri = Uri.parse(html.window.location.href);
    final newUri = currentUri.replace(
      queryParameters: {
        ...currentUri.queryParameters,
        'v': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    html.window.location.href = newUri.toString();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('利用規約・プライバシーポリシー', style: TextStyle(fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          height: 380,
          child: const SingleChildScrollView(
            child: SelectableText(
              AppConstants.termsAndPrivacyText,
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _openContactForm() {
    html.window.open(AppConstants.contactFormUrl, '_blank');
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
            // ==========================================
            // 1. 【基本設定】
            // ==========================================
            const Text(
              'Groq API Key',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Groq Console で取得した無料APIキー（gsk_...）を入力してください。端末内のみに安全に保存されます。',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                  tooltip: _obscureApiKey ? 'キーを表示' : 'キーを隠す',
                  onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await ref.read(settingsProvider.notifier).updateSettings(
                        apiKey: _apiKeyController.text.trim(),
                        modelName: _modelController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('設定を保存しました')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('設定を保存'),
              ),
            ),

            const Divider(height: 28),

            // ==========================================
            // 2. 【サポート・アプリ情報】
            // ==========================================
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, color: Colors.teal),
              title: const Text('利用規約・プライバシーポリシー', style: TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _showTermsDialog,
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.mail_outline, color: Colors.teal),
              title: const Text('お問い合わせ・不具合報告', style: TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.open_in_new, size: 14),
              onTap: _openContactForm,
            ),

            const Divider(height: 28),

            // ==========================================
            // 3. 【詳細・メンテナンス】（初期状態は折りたたみ）
            // ==========================================
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  '詳細・メンテナンス',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                ),
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: '使用AIモデル指定',
                      border: OutlineInputBorder(),
                      isDense: true,
                      helperText: '※通常は変更不要です',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bug_report, size: 16),
                      label: const Text('エラーログを確認'),
                      onPressed: () {
                        showDialog(context: context, builder: (_) => const ErrorLogDialog());
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
                      icon: _isReloading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(_isReloading ? '更新中...' : 'キャッシュを削除して最新版に更新'),
                      onPressed: _isReloading ? null : _forceUpdateApp,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'アプリバージョン: v${AppConstants.appVersion}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
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
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}