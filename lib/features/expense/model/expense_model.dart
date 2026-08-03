class Expense {
  final String id;
  final String shiftId;
  final String title;
  final double amount;
  final String note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Expense({
    required this.id,
    required this.shiftId,
    required this.title,
    required this.amount,
    required this.note,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shift_id': shiftId,
      'title': title,
      'amount': amount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      shiftId: map['shift_id'] as String,
      title: map['title'] as String? ?? 'Expense',
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
    );
  }

  Expense copyWith({
    String? id,
    String? shiftId,
    String? title,
    double? amount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.shiftId == shiftId &&
        other.title == title &&
        other.amount == amount &&
        other.note == note &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, shiftId, title, amount, note, createdAt, updatedAt);
}
