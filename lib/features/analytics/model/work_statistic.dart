import '../../work/model/work_model.dart';

class WorkStatistic {
  final Work work;
  final int shiftCount;
  final double income;
  final double expense;

  const WorkStatistic({
    required this.work,
    required this.shiftCount,
    required this.income,
    required this.expense,
  });

  double get profit => income - expense;
}
