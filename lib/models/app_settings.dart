import 'dart:convert';
import '../core/constants/app_constants.dart';

class AppSettings {
  final String apiKey;
  final bool forceLocalOcr; // ★手動で標準（ローカルOCR）モードを使うフラグ

  AppSettings({
    this.apiKey = '',
    this.forceLocalOcr = false,
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;

  // 現在動作するモードがAIかローカルかを判定
  bool get isAiMode => isConfigured && !forceLocalOcr;

  AppSettings copyWith({
    String? apiKey,
    bool? forceLocalOcr,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      forceLocalOcr: forceLocalOcr ?? this.forceLocalOcr,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'forceLocalOcr': forceLocalOcr,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      apiKey: map['apiKey'] ?? '',
      forceLocalOcr: map['forceLocalOcr'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source));
}