class Shift {
  final String id;

  final String workId;

  final DateTime workDate;

  final String startTime;

  final String endTime;

  final double income;

  final double expense;

  final String note;

  Shift({
    required this.id,
    required this.workId,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.income,
    required this.expense,
    required this.note,
  });

  double get profit => income - expense;

  DateTime? _parseTime(String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return DateTime(workDate.year, workDate.month, workDate.day, hour, minute);
  }

  DateTime? get startDateTime => _parseTime(startTime);

  DateTime? get endDateTime => _parseTime(endTime);

  Duration get duration {
    final start = startDateTime;
    final end = endDateTime;
    if (start == null || end == null) return Duration.zero;
    if (end.isBefore(start)) return Duration.zero;
    return end.difference(start);
  }

  double get hoursWorked => duration.inMinutes / 60.0;

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "workId": workId,
      "workDate": workDate.toIso8601String(),
      "startTime": startTime,
      "endTime": endTime,
      "income": income,
      "expense": expense,
      "note": note,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map["id"],
      workId: map["workId"],
      workDate: DateTime.parse(map["workDate"]),
      startTime: map["startTime"],
      endTime: map["endTime"],
      income: (map["income"] as num).toDouble(),
      expense: (map["expense"] as num).toDouble(),
      note: map["note"],
    );
  }

  Shift copyWith({
    String? id,
    String? workId,
    DateTime? workDate,
    String? startTime,
    String? endTime,
    double? income,
    double? expense,
    String? note,
  }) {
    return Shift(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      workDate: workDate ?? this.workDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      note: note ?? this.note,
    );
  }
}
