import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/receipt_item.dart';

class StorageService {
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeySettings, settings.toJson());
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppConstants.prefKeySettings);
    if (jsonStr == null || jsonStr.isEmpty) return AppSettings();
    try {
      return AppSettings.fromJson(jsonStr);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveReceipts(List<ReceiptItem> receipts) async {
    final prefs = await SharedPreferences.getInstance();
    final list = receipts.map((item) => item.toMap()).toList();
    await prefs.setString(AppConstants.prefKeyReceipts, json.encode(list));
  }

  Future<List<ReceiptItem>> loadReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppConstants.prefKeyReceipts);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((e) => ReceiptItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearReceiptCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefKeyReceipts);
  }
}