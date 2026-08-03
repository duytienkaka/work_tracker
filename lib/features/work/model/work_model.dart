class Work {
  final String id;
  final String name;
  final String description;

  /// 0 = Legacy fixed
  /// 1 = Daily
  /// 2 = Hourly
  /// 3 = Freelance
  final int salaryType;
  final double dailyRate;
  final double hourlyRate;

  final int color;
  final int icon;
  final bool isActive;
  final DateTime createdAt;

  Work({
    required this.id,
    required this.name,
    required this.description,
    required this.salaryType,
    required this.dailyRate,
    required this.hourlyRate,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.createdAt,
  });

  static const int legacyFixed = 0;
  static const int daily = 1;
  static const int hourly = 2;
  static const int freelance = 3;

  static String salaryTypeLabel(int type) {
    switch (type) {
      case daily:
        return 'Theo ngày';
      case hourly:
        return 'Theo giờ';
      case freelance:
        return 'Freelance';
      case legacyFixed:
      default:
        return 'Lương cố định';
    }
  }

  String get salaryTypeName => salaryTypeLabel(salaryType);

  String get salaryRateDescription {
    switch (salaryType) {
      case daily:
        return 'Mức lương ngày: $dailyRate';
      case hourly:
        return 'Mức lương giờ: $hourlyRate';
      default:
        return '';
    }
  }

  bool get hasSalaryRate => salaryType == daily || salaryType == hourly;

  double computeSalaryForShift({
    required DateTime startDateTime,
    required DateTime? endDateTime,
  }) {
    if (salaryType == daily) {
      return dailyRate;
    }

    if (salaryType == hourly) {
      if (endDateTime == null) {
        return 0;
      }

      final duration = endDateTime.difference(startDateTime);
      if (duration.isNegative) {
        return 0;
      }

      return hourlyRate * duration.inMinutes / 60.0;
    }

    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "salaryType": salaryType,
      "dailyRate": dailyRate,
      "hourlyRate": hourlyRate,
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
      salaryType: map["salaryType"] ?? legacyFixed,
      dailyRate: (map["dailyRate"] as num?)?.toDouble() ?? 0,
      hourlyRate: (map["hourlyRate"] as num?)?.toDouble() ?? 0,
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
    double? dailyRate,
    double? hourlyRate,
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
      dailyRate: dailyRate ?? this.dailyRate,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Work && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
