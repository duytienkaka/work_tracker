class Work {
  final String id;
  final String name;
  final String description;

  /// 0 = Fixed
  /// 1 = Daily
  /// 2 = Hourly
  /// 3 = Freelance
  final int salaryType;

  final int color;

  final int icon;

  final bool isActive;

  final DateTime createdAt;

  Work({
    required this.id,
    required this.name,
    required this.description,
    required this.salaryType,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "salaryType": salaryType,
      "color": color,
      "icon": icon,
      "isActive": isActive ? 1 : 0,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory Work.fromMap(Map<String, dynamic> map) {
    return Work(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      salaryType: map["salaryType"],
      color: map["color"],
      icon: map["icon"],
      isActive: map["isActive"] == 1,
      createdAt: DateTime.parse(map["createdAt"]),
    );
  }

  Work copyWith({
    String? id,
    String? name,
    String? description,
    int? salaryType,
    int? color,
    int? icon,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Work(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      salaryType: salaryType ?? this.salaryType,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
