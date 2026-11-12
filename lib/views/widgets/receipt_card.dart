import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/receipt_item.dart';
import 'receipt_edit_modal.dart';

class ReceiptCard extends StatelessWidget {
  final ReceiptItem item;
  final Function(ReceiptItem) onUpdate;
  final VoidCallback onDelete;

  const ReceiptCard({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###', 'ja_JP');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: item.thumbnailBase64 != null
            ? GestureDetector(
                onTap: () => _showImageDialog(context, item.thumbnailBase64!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(item.thumbnailBase64!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.grey),
              ),
        title: Text(
          item.store,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // ← ここを修正しました！
        ),
        subtitle: Text(
          item.date,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¥${currencyFormatter.format(item.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  showDialog(
                    context: context,
                    builder: (ctx) => ReceiptEditModal(
                      initialItem: item,
                      onSave: (date, store, amount) {
                        onUpdate(item.copyWith(date: date, store: store, amount: amount));
                      },
                    ),
                  );
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('修正する')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('削除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String base64) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(base64Decode(base64)),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}