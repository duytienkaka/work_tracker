class ShiftTemplate {
  final String id;
  final String name;
  final String workId;
  final String startTime;
  final String endTime;
  final String note;

  const ShiftTemplate({
    required this.id,
    required this.name,
    required this.workId,
    required this.startTime,
    required this.endTime,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'workId': workId,
    'startTime': startTime,
    'endTime': endTime,
    'note': note,
  };

  factory ShiftTemplate.fromJson(Map<String, dynamic> json) => ShiftTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    workId: json['workId'] as String,
    startTime: json['startTime'] as String,
    endTime: json['endTime'] as String,
    note: json['note'] as String? ?? '',
  );
}
