import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_header.dart';
import '../../dashboard/widgets/quick_actions.dart';
import '../../dashboard/widgets/recent_shift_card.dart';
import '../../dashboard/widgets/summary_grid.dart';
import '../../timeline/screen/timeline_page.dart';
import '../../analytics/screen/analytics_page.dart';
import '../../shift/screen/shift_form_page.dart';
import '../../work/provider/work_provider.dart';
import '../../work/screen/work_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    Future.microtask(() async {
      if (!mounted) return;
      await _reloadData();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reloadData() async {
    final dashboardProvider = context.read<DashboardProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    await dashboardProvider.load();
    await analyticsProvider.load();
  }

  Future<void> _openPage(Widget page) async {
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(builder: (_) => page));

    if (!mounted) return;
    await _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _reloadData();
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: const DashboardHeader(),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Consumer<AnalyticsProvider>(
                  builder: (_, analytics, _) {
                    if (analytics.summary == null) {
                      return const LoadingView();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SummaryGrid(
                          income: dashboard.dashboard?.incomeToday ?? 0,
                          expense: dashboard.dashboard?.expenseToday ?? 0,
                          profit: dashboard.dashboard?.profitToday ?? 0,
                          totalShift: analytics.summary?.totalShift ?? 0,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        QuickActions(
                          onAddShift: () async {
                            await context.read<WorkProvider>().loadWorks();
                            await _openPage(const ShiftFormPage());
                          },
                          onAddWork: () async {
                            await _openPage(const WorkFormPage());
                          },
                          onOpenTimeline: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TimelinePage(),
                              ),
                            );
                          },
                          onOpenAnalytics: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnalyticsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (dashboard.dashboard?.recentShift != null) ...[
                          const Text(
                            'Ca làm gần đây',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          RecentShiftCard(
                            shift: dashboard.dashboard!.recentShift!,
                          ),
                        ] else
                          const EmptyState(
                            icon: Icons.work_history_outlined,
                            title: 'Chưa có ca làm gần đây',
                            subtitle:
                                'Hãy thêm ca làm đầu tiên để bắt đầu theo dõi.',
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await context.read<WorkProvider>().loadWorks();
          await _openPage(const ShiftFormPage());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
