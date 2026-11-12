import 'dart:convert';

class ReceiptItem {
  final String id;
  final String date;
  final String store;
  final int amount;
  final String? thumbnailBase64;
  final DateTime createdAt;

  ReceiptItem({
    required this.id,
    required this.date,
    required this.store,
    required this.amount,
    this.thumbnailBase64,
    required this.createdAt,
  });

  ReceiptItem copyWith({
    String? id,
    String? date,
    String? store,
    int? amount,
    String? thumbnailBase64,
    DateTime? createdAt,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      date: date ?? this.date,
      store: store ?? this.store,
      amount: amount ?? this.amount,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'store': store,
      'amount': amount,
      'thumbnailBase64': thumbnailBase64,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      store: map['store'] ?? '不明な店舗',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      thumbnailBase64: map['thumbnailBase64'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReceiptItem.fromJson(String source) =>
      ReceiptItem.fromMap(json.decode(source));
}