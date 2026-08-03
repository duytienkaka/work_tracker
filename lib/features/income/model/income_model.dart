class Income {
  final String id;
  final String shiftId;
  final String title;
  final double amount;
  final double tip;
  final String note;
  final bool generated;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Income({
    required this.id,
    required this.shiftId,
    required this.title,
    required this.amount,
    required this.tip,
    required this.note,
    this.generated = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shift_id': shiftId,
      'title': title,
      'amount': amount,
      'tip': tip,
      'note': note,
      'generated': generated ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as String,
      shiftId: map['shift_id'] as String,
      title: map['title'] as String? ?? 'Income',
      amount: (map['amount'] as num).toDouble(),
      tip: (map['tip'] as num).toDouble(),
      note: map['note'] as String? ?? '',
      generated: (map['generated'] as num?)?.toInt() == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.parse(map['updated_at'] as String),
    );
  }

  Income copyWith({
    String? id,
    String? shiftId,
    String? title,
    double? amount,
    double? tip,
    String? note,
    bool? generated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      tip: tip ?? this.tip,
      note: note ?? this.note,
      generated: generated ?? this.generated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
