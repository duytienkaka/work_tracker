import '../../shift/model/shift_model.dart';
import '../../shift/repository/shift_repository.dart';
import '../model/timeline_item.dart';

class TimelineRepository {
  Future<List<TimelineItem>> getTimeline() async {
    final repository = ShiftRepository();
    final shifts = await repository.getAll();

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
