import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const SectionTitle({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.title)),
          action ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
