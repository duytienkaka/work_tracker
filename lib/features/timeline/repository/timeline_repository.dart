import '../../shift/model/shift_model.dart';
import '../model/timeline_item.dart';

import '../../../core/database/app_database.dart';

class TimelineRepository {
  Future<List<TimelineItem>> getTimeline() async {
    final db = await AppDatabase.database();

    final result = await db.query(
      "shifts",
      orderBy: "workDate DESC,startTime DESC",
    );

    final shifts = result.map((e) => Shift.fromMap(e)).toList();

    final Map<String, List<Shift>> map = {};

    for (final shift in shifts) {
      final dateKey = shift.workDate.toIso8601String();

      map.putIfAbsent(dateKey, () => []);
      map[dateKey]!.add(shift);
    }

    return map.entries
        .map((e) => TimelineItem(date: e.key, shifts: e.value))
        .toList();
  }
}
