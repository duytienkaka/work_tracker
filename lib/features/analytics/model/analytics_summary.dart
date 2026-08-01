class AnalyticsSummary {
  final double totalIncome;
  final double totalExpense;
  final int totalShift;
  final double averageIncome;

  const AnalyticsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalShift,
    required this.averageIncome,
  });

  double get profit => totalIncome - totalExpense;
}
