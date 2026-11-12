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

  void _sortByDate() {
    state = [...state]..sort((a, b) => a.date.compareTo(b.date));
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