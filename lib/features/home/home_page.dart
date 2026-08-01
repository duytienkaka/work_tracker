import 'package:flutter/material.dart';

import '../../shared/widgets/empty_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyState(
        icon: Icons.home_outlined,
        title: 'Work Tracker',
        subtitle: 'Bản phát hành 1.0.0 đang sẵn sàng.',
      ),
    );
  }
}
