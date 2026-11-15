import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/receipt_provider.dart';

class SummaryHeader extends ConsumerWidget {
  final bool isAiMode;
  final VoidCallback onModeTap;
  final bool isDailyGrouping;
  final ValueChanged<bool> onGroupingChanged;

  const SummaryHeader({
    super.key,
    required this.isAiMode,
    required this.onModeTap,
    required this.isDailyGrouping,
    required this.onGroupingChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(totalAmountProvider);
    final count = ref.watch(receiptListProvider).length;
    final currencyFormatter = NumberFormat('#,###', 'ja_JP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ★【プロデューサー案完全再現】支出サマリー ＆ モードバッジ
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '支出サマリー',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: onModeTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAiMode ? const Color(0xFFFBF4FF) : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isAiMode ? const Color(0xFFE2C4FF) : Colors.teal.shade300,
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
              ),
            ],
          ),
        ),

        // サマリーカード本体（水色）
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50.withOpacity(0.7),
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
                  const SizedBox(height: 2),
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
        ),

        // ★【新機能】明細順 / 日別まとめ 切り替えタブ
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildTabButton(
                      label: '明細順',
                      isSelected: !isDailyGrouping,
                      onTap: () => onGroupingChanged(false),
                    ),
                    _buildTabButton(
                      label: '日別まとめ',
                      isSelected: isDailyGrouping,
                      onTap: () => onGroupingChanged(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 2, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.teal.shade900 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}