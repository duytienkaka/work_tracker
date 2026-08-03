import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../../shift/screen/shift_detail_page.dart';
import '../../shift/screen/shift_form_page.dart';
import '../model/work_summary.dart';
import '../provider/work_provider.dart';

class WorkDetailPage extends StatefulWidget {
  final WorkSummary summary;

  const WorkDetailPage({super.key, required this.summary});

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<WorkProvider>().loadWorkDetail(widget.summary.work.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;

    return Consumer<WorkProvider>(
      builder: (context, provider, _) {
        final totalIncome = provider.currentWorkShifts.fold<double>(
          0,
          (sum, shift) => sum + shift.income,
        );
        final totalExpense = provider.currentWorkShifts.fold<double>(
          0,
          (sum, shift) => sum + shift.expense,
        );
        final profit = totalIncome - totalExpense;

        return Scaffold(
          appBar: AppBar(
            title: Text(summary.work.name),
            actions: [
              IconButton(
                tooltip: 'Thêm ca làm',
                onPressed: () async {
                  final workProvider = context.read<WorkProvider>();
                  final currentContext = context;

                  await Navigator.push(
                    currentContext,
                    MaterialPageRoute(
                      builder: (_) => ShiftFormPage(work: summary.work),
                    ),
                  );

                  if (!currentContext.mounted) return;
                  if (!mounted) return;
                  await workProvider.loadWorkDetail(summary.work.id);
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                summary.work.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary.work.description.isEmpty
                    ? 'Không có mô tả'
                    : summary.work.description,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _SummaryBlock(
                title: 'Tổng thu',
                value: MoneyFormatter.format(totalIncome),
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              _SummaryBlock(
                title: 'Tổng chi',
                value: MoneyFormatter.format(totalExpense),
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              _SummaryBlock(
                title: 'Lợi nhuận',
                value: MoneyFormatter.format(profit),
                color: AppColors.success,
              ),
              const SizedBox(height: 16),
              const Text(
                'Timeline',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (provider.currentWorkShifts.isEmpty)
                const EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Chưa có ca làm',
                  subtitle: 'Hãy thêm ca làm đầu tiên cho công việc này.',
                )
              else
                Column(
                  children: provider.currentWorkShifts.map((shift) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () async {
                          final workProvider = context.read<WorkProvider>();
                          final currentContext = context;

                          await Navigator.push(
                            currentContext,
                            MaterialPageRoute(
                              builder: (_) => ShiftDetailPage(
                                work: summary.work,
                                shift: shift,
                              ),
                            ),
                          );
                          if (!currentContext.mounted) return;
                          if (!mounted) return;
                          await workProvider.loadWorkDetail(summary.work.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${shift.startTime} → ${shift.endTime}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.schedule, size: 18),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                shift.workDate.toString().substring(0, 10),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Thu',
                                      value: MoneyFormatter.format(
                                        shift.income,
                                      ),
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Chi',
                                      value: MoneyFormatter.format(
                                        shift.expense,
                                      ),
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _MiniMetric(
                                      label: 'Lợi nhuận',
                                      value: MoneyFormatter.format(
                                        shift.profit,
                                      ),
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryBlock({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
