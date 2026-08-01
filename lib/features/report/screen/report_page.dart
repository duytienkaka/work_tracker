import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.insert_chart_outlined,
        title: 'Báo cáo sẽ sớm có mặt',
        subtitle:
            'Phần báo cáo đang được chuẩn bị cho bản phát hành tiếp theo.',
      ),
    );
  }
}
