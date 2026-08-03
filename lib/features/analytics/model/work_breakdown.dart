import '../../work/model/work_model.dart';

class WorkBreakdown {
  final Work work;
  final double value;
  final int count;

  const WorkBreakdown({
    required this.work,
    required this.value,
    required this.count,
  });
}
