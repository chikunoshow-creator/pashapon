import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiKeyController = TextEditingController(text: settings.apiKey);
    _modelController = TextEditingController(text: settings.modelName);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('設定 (Groq API)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Groq Console で取得した無料APIキー（gsk_...）を入力してください。端末内のみに保存されます。',
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
                helperText: '例: llama-3.2-11b-vision-preview',
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