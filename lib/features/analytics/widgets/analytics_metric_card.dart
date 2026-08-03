import 'package:flutter/material.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';

class AnalyticsMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? helperText;
  final IconData icon;
  final Color color;

  const AnalyticsMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
