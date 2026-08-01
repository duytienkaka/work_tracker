import 'shift_model.dart';

class TimelineItem {
  final String date;

  final List<Shift> shifts;

  TimelineItem({required this.date, required this.shifts});

  double get income => shifts.fold(0, (a, b) => a + b.income);

  double get expense => shifts.fold(0, (a, b) => a + b.expense);

  double get profit => income - expense;
}
