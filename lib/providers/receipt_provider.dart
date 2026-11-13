import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/receipt_item.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

final receiptListProvider = StateNotifierProvider<ReceiptListNotifier, List<ReceiptItem>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ReceiptListNotifier(storage);
});

class ReceiptListNotifier extends StateNotifier<List<ReceiptItem>> {
  final StorageService _storage;
  final Uuid _uuid = const Uuid();

  ReceiptListNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadReceipts();
    _sortByDate();
  }

  /// ★表記ゆれ（スラッシュ、年省略、空白等）を吸収してDateTimeに変換する安全関数
  static DateTime _parseDateSafe(String rawDate) {
    if (rawDate.trim().isEmpty) return DateTime(1970);

    // 空白除去、スラッシュや年月日をハイフンに統一
    String cleaned = rawDate.trim()
        .replaceAll('/', '-')
        .replaceAll('年', '-')
        .replaceAll('月', '-')
        .replaceAll('日', '');

    // "11-13" のように年が抜けている場合は今年（2026）を補完
    final parts = cleaned.split('-');
    if (parts.length == 2) {
      cleaned = '${DateTime.now().year}-$cleaned';
    }

    final parsed = DateTime.tryParse(cleaned);
    if (parsed != null) return parsed;

    return DateTime(1970); // どうしても解析できないものは最古扱い
  }

  /// ★カレンダー日付（DateTime）による厳格な昇順ソート
  void _sortByDate() {
    state = [...state]..sort((a, b) {
      final dateA = _parseDateSafe(a.date);
      final dateB = _parseDateSafe(b.date);

      final dateCompare = dateA.compareTo(dateB);
      if (dateCompare != 0) return dateCompare;

      // 日付が同じ場合は、登録日時（撮影順）で整列
      return a.createdAt.compareTo(b.createdAt);
    });
  }

  Future<void> addReceipt({
    required String date,
    required String store,
    required int amount,
    String? thumbnailBase64,
  }) async {
    final newItem = ReceiptItem(
      id: _uuid.v4(),
      date: date,
      store: store,
      amount: amount,
      thumbnailBase64: thumbnailBase64,
      createdAt: DateTime.now(),
    );
    state = [...state, newItem];
    _sortByDate();
    await _storage.saveReceipts(state);
  }

  Future<void> updateReceipt(ReceiptItem updated) async {
    state = [
      for (final item in state)
        if (item.id == updated.id) updated else item,
    ];
    _sortByDate();
    await _storage.saveReceipts(state);
  }

  Future<void> deleteReceipt(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _storage.saveReceipts(state);
  }

  Future<void> clearAll() async {
    state = [];
    await _storage.clearReceiptCache();
  }
}

// 合計金額を算出するProvider
final totalAmountProvider = Provider<int>((ref) {
  final receipts = ref.watch(receiptListProvider);
  return receipts.fold(0, (sum, item) => sum + item.amount);
});