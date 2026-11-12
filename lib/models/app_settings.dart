import 'dart:convert';
import '../core/constants/app_constants.dart';

class AppSettings {
  final String apiKey;
  final String modelName;

  AppSettings({
    this.apiKey = '',
    this.modelName = AppConstants.defaultGroqModel,
  });

  bool get isConfigured => apiKey.trim().isNotEmpty;

  AppSettings copyWith({
    String? apiKey,
    String? modelName,
  }) {
    return AppSettings(
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'modelName': modelName,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      apiKey: map['apiKey'] ?? '',
      modelName: map['modelName'] ?? AppConstants.defaultGroqModel,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppSettings.fromJson(String source) =>
      AppSettings.fromMap(json.decode(source));
}