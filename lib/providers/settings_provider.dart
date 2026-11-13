import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

// 初期読み込み完了フラグ
final settingsInitializedProvider = StateProvider<bool>((ref) => false);

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage, ref);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;
  final Ref _ref;

  SettingsNotifier(this._storage, this._ref) : super(AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadSettings();
    _ref.read(settingsInitializedProvider.notifier).state = true;
  }

  Future<void> updateSettings({required String apiKey, required String modelName}) async {
    final updated = state.copyWith(apiKey: apiKey, modelName: modelName);
    state = updated;
    await _storage.saveSettings(updated);
  }
}