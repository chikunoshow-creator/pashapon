import 'dart:convert';

class ErrorLog {
  final String id;
  final String timestamp;
  final String errorType;
  final String message;
  final String? details;

  ErrorLog({
    required this.id,
    required this.timestamp,
    required this.errorType,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'errorType': errorType,
      'message': message,
      'details': details,
    };
  }

  factory ErrorLog.fromMap(Map<String, dynamic> map) {
    return ErrorLog(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] ?? '',
      errorType: map['errorType'] ?? 'Error',
      message: map['message'] ?? '',
      details: map['details'],
    );
  }

  String toJson() => json.encode(toMap());

  factory ErrorLog.fromJson(String source) =>
      ErrorLog.fromMap(json.decode(source));
}