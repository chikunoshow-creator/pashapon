import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.loadSettings();
  }

  Future<void> updateSettings({required String apiKey, required String modelName}) async {
    final updated = state.copyWith(apiKey: apiKey, modelName: modelName);
    state = updated;
    await _storage.saveSettings(updated);
  }
}