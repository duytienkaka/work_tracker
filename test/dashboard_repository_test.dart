import 'package:flutter_test/flutter_test.dart';
import 'package:work_tracker/features/dashboard/repository/dashboard_repository.dart';
import 'package:work_tracker/features/shift/model/shift_model.dart';

void main() {
  test('selects todays shift when a newer shift exists on another day', () {
    final today = DateTime(2025, 1, 10);
    final yesterday = Shift(
      id: 'yesterday',
      workId: 'work-1',
      workDate: DateTime(2025, 1, 9),
      startTime: '09:00',
      endTime: '17:00',
      income: 0,
      expense: 0,
      note: '',
    );
    final todayShift = Shift(
      id: 'today',
      workId: 'work-1',
      workDate: DateTime(2025, 1, 10),
      startTime: '10:00',
      endTime: '18:00',
      income: 0,
      expense: 0,
      note: '',
    );

    final selected = DashboardRepository.selectActiveShiftForToday([
      yesterday,
      todayShift,
    ], today);

    expect(selected?.id, 'today');
  });

  test(
    'prefers the current in-progress shift before the next upcoming shift',
    () {
      final today = DateTime(2025, 1, 10);
      final now = DateTime(2025, 1, 10, 12, 0);
      final completedShift = Shift(
        id: 'completed',
        workId: 'work-1',
        workDate: today,
        startTime: '08:00',
        endTime: '10:00',
        income: 0,
        expense: 0,
        note: '',
      );
      final activeShift = Shift(
        id: 'active',
        workId: 'work-1',
        workDate: today,
        startTime: '10:00',
        endTime: '14:00',
        income: 0,
        expense: 0,
        note: '',
      );
      final upcomingShift = Shift(
        id: 'upcoming',
        workId: 'work-1',
        workDate: today,
        startTime: '15:00',
        endTime: '18:00',
        income: 0,
        expense: 0,
        note: '',
      );

      final selected = DashboardRepository.selectActiveShiftForToday(
        [completedShift, activeShift, upcomingShift],
        today,
        now,
      );

      expect(selected?.id, 'active');
    },
  );
}
