import 'package:flutter/material.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddShift;
  final VoidCallback onAddWork;
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenAnalytics;

  const QuickActions({
    super.key,
    required this.onAddShift,
    required this.onAddWork,
    required this.onOpenTimeline,
    required this.onOpenAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        icon: Icons.work_history_rounded,
        label: 'Ca làm',
        onTap: onAddShift,
        color: AppColors.primary,
      ),
      _ActionItem(
        icon: Icons.add_task_rounded,
        label: 'Công việc',
        onTap: onAddWork,
        color: AppColors.secondary,
      ),
      _ActionItem(
        icon: Icons.timeline_rounded,
        label: 'Dòng thời gian',
        onTap: onOpenTimeline,
        color: AppColors.success,
      ),
      _ActionItem(
        icon: Icons.analytics_rounded,
        label: 'Phân tích',
        onTap: onOpenAnalytics,
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: actions.map((action) => _ActionCard(action: action)).toList(),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _ActionItem action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const Spacer(),
              Text(action.label, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });
}
