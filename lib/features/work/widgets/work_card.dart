import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import '../model/work_summary.dart';
import '../provider/work_provider.dart';
import '../screen/work_detail_page.dart';

class WorkCard extends StatelessWidget {
  final WorkSummary summary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WorkCard({
    super.key,
    required this.summary,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  String get salaryType {
    switch (summary.work.salaryType) {
      case 0:
        return 'Lương cố định';
      case 1:
        return 'Theo ngày';
      case 2:
        return 'Theo giờ';
      case 3:
        return 'Freelancer';
      default:
        return 'Khác';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'work-${summary.work.id}',
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(
                      summary.work.color,
                    ).withValues(alpha: 0.16),
                    child: Icon(
                      IconData(summary.work.icon, fontFamily: 'MaterialIcons'),
                      color: Color(summary.work.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.work.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salaryType,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Đang hoạt động',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.work.description.isEmpty
                    ? 'Không có mô tả'
                    : summary.work.description,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              FutureBuilder<WorkSummary>(
                future: () {
                  try {
                    final provider = context.read<WorkProvider>();
                    return provider.getSummary(summary.work.id);
                  } catch (_) {
                    return Future<WorkSummary>.value(summary);
                  }
                }(),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? summary;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Ca',
                              value: '${stats.totalShift} ca',
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              label: 'Thu',
                              value: MoneyFormatter.format(stats.income),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Chi',
                              value: MoneyFormatter.format(stats.expense),
                            ),
                          ),
                          Expanded(
                            child: _StatTile(
                              label: 'Lợi nhuận',
                              value: MoneyFormatter.format(stats.profit),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Sửa'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkDetailPage(summary: summary),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart, size: 18),
                    label: const Text('Chi tiết'),
                  ),
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
