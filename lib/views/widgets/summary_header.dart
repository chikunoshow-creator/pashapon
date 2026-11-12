import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/receipt_provider.dart';

class SummaryHeader extends ConsumerWidget {
  const SummaryHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(totalAmountProvider);
    final count = ref.watch(receiptListProvider).length;
    final currencyFormatter = NumberFormat('#,###', 'ja_JP');

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('合計件数', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text('$count 件', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('合計金額', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(
                '¥${currencyFormatter.format(total)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}