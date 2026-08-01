import '../../shift/model/shift_model.dart';

class TimelineItem {
  final String date;
  final List<Shift> shifts;
  bool isExpanded;

  TimelineItem({
    required this.date,
    required this.shifts,
    this.isExpanded = false,
  });

  double get income => shifts.fold(0, (sum, shift) => sum + shift.income);

  double get expense => shifts.fold(0, (sum, shift) => sum + shift.expense);

  double get profit => income - expense;

  int get totalShift => shifts.length;
}
