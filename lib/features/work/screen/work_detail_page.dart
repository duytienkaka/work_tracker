import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.work.name),
        actions: [
          IconButton(
            tooltip: 'Thêm ca làm',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShiftFormPage(work: summary.work),
                ),
              );

              if (!mounted) return;
              if (!context.mounted) return;
              await context.read<WorkProvider>().loadWorkDetail(
                summary.work.id,
              );
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
            value: MoneyFormatter.format(summary.totalIncome),
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _SummaryBlock(
            title: 'Tổng chi',
            value: MoneyFormatter.format(summary.totalExpense),
            color: AppColors.danger,
          ),
          const SizedBox(height: 12),
          _SummaryBlock(
            title: 'Lợi nhuận',
            value: MoneyFormatter.format(summary.profit),
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          const Text(
            'Timeline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Consumer<WorkProvider>(
            builder: (context, provider, _) {
              if (provider.currentWorkShifts.isEmpty) {
                return const EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Chưa có ca làm',
                  subtitle: 'Hãy thêm ca làm đầu tiên cho công việc này.',
                );
              }

              return Column(
                children: provider.currentWorkShifts.map((shift) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text('${shift.startTime} → ${shift.endTime}'),
                      subtitle: Text(
                        shift.workDate.toString().substring(0, 10),
                      ),
                      trailing: Text(MoneyFormatter.format(shift.income)),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShiftFormPage(
                              work: summary.work,
                              shift: shift,
                            ),
                          ),
                        );
                        if (!mounted) return;
                        await context.read<WorkProvider>().loadWorkDetail(
                          summary.work.id,
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
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
