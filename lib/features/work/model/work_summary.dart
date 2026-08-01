import 'work_model.dart';

class WorkSummary {
  final Work work;
  final String workId;
  final int totalShifts;
  final double totalIncome;
  final double totalExpense;
  final int totalShift;
  final double income;
  final double expense;

  WorkSummary({
    required this.work,
    int? totalShifts,
    double? totalIncome,
    double? totalExpense,
    String? workId,
    int? totalShift,
    double? income,
    double? expense,
  }) : totalShifts = totalShifts ?? 0,
       totalIncome = totalIncome ?? 0,
       totalExpense = totalExpense ?? 0,
       workId = workId ?? work.id,
       totalShift = totalShift ?? totalShifts ?? 0,
       income = income ?? totalIncome ?? 0,
       expense = expense ?? totalExpense ?? 0;

  double get profit => totalIncome - totalExpense;
}
