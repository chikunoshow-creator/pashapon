import 'package:flutter/material.dart';
import '../../models/receipt_item.dart';

class ReceiptEditModal extends StatefulWidget {
  final ReceiptItem? initialItem;
  final Function(String date, String store, int amount) onSave;

  const ReceiptEditModal({
    super.key,
    this.initialItem,
    required this.onSave,
  });

  @override
  State<ReceiptEditModal> createState() => _ReceiptEditModalState();
}

class _ReceiptEditModalState extends State<ReceiptEditModal> {
  late TextEditingController _dateController;
  late TextEditingController _storeController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
      text: widget.initialItem?.date ?? DateTime.now().toIso8601String().substring(0, 10),
    );
    _storeController = TextEditingController(text: widget.initialItem?.store ?? '');
    _amountController = TextEditingController(
      text: widget.initialItem != null ? widget.initialItem!.amount.toString() : '',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _storeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialItem == null ? '手入力で追加' : 'レシート内容の修正'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: '購入日 (YYYY-MM-DD)', icon: Icon(Icons.calendar_today)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _storeController,
              decoration: const InputDecoration(labelText: '店名', icon: Icon(Icons.store)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '合計金額 (円)', icon: Icon(Icons.currency_yen)),
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
          onPressed: () {
            final store = _storeController.text.trim();
            final amount = int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
            final date = _dateController.text.trim();
            widget.onSave(date, store, amount);
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}