import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/error_log.dart';
import '../../services/storage_service.dart';

class ErrorLogDialog extends StatefulWidget {
  const ErrorLogDialog({super.key});

  @override
  State<ErrorLogDialog> createState() => _ErrorLogDialogState();
}

class _ErrorLogDialogState extends State<ErrorLogDialog> {
  final StorageService _storage = StorageService();
  List<ErrorLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final list = await _storage.loadErrorLogs();
    if (mounted) {
      setState(() {
        _logs = list;
        _loading = false;
      });
    }
  }

  void _copyAllLogs() {
    if (_logs.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln('📋 【パシャぽん エラーログ報告】');
    for (final log in _logs) {
      buffer.writeln('-----------------------------------');
      buffer.writeln('日時: ${log.timestamp}');
      buffer.writeln('種別: ${log.errorType}');
      buffer.writeln('概要: ${log.message}');
      if (log.details != null) {
        buffer.writeln('詳細:\n${log.details}');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('エラーログ全文をクリップボードにコピーしました！')),
    );
  }

  Future<void> _clearLogs() async {
    await _storage.clearErrorLogs();
    setState(() {
      _logs = [];
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エラーログを消去しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.bug_report, color: Colors.redAccent),
          const SizedBox(width: 8),
          const Text('エラーログ', style: TextStyle(fontSize: 18)),
          const Spacer(),
          if (_logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'ログを全文コピー',
              onPressed: _copyAllLogs,
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 380,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
                ? const Center(
                    child: Text('現在、エラーログはありません 🕊️', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _logs[index];
                      return ExpansionTile(
                        dense: true,
                        title: Text(
                          item.message,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${item.timestamp} [${item.errorType}]',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            color: Colors.grey.shade100,
                            child: SelectableText(
                              item.details ?? '(詳細なし)',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
      actions: [
        if (_logs.isNotEmpty)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _clearLogs,
            child: const Text('ログ全消去'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}