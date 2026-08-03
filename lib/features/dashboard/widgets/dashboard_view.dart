import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../theme/app_colors.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../analytics/screen/analytics_page.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../expense/model/expense_model.dart';
import '../../income/model/income_model.dart';
import '../../settings/screen/settings_page.dart';
import '../../shift/model/shift_model.dart';
import '../../shift/screen/shift_form_page.dart';
import '../../timeline/screen/timeline_page.dart';
import '../../work/model/work_model.dart';
import '../../work/provider/work_provider.dart';
import '../../work/screen/work_form_page.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
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
    await Future.wait([
      context.read<DashboardProvider>().load(),
      context.read<AnalyticsProvider>().load(),
    ]);
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    if (!mounted) return;
    await _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final analyticsProvider = context.watch<AnalyticsProvider>();

    if (dashboardProvider.dashboard == null ||
        analyticsProvider.summary == null) {
      return const Scaffold(
        body: Center(
          child: Padding(padding: EdgeInsets.all(24), child: LoadingView()),
        ),
      );
    }

    final dashboard = dashboardProvider.dashboard!;
    final today = DateTime.now();
    final todayOrders = _todayOrders(analyticsProvider.incomeItems, today);
    final todayIncomeItems = _todayIncomeItems(
      analyticsProvider.incomeItems,
      today,
    );
    final recentOrders = _recentIncomeItems(analyticsProvider.incomeItems);
    final recentExpenses = _recentExpenses(analyticsProvider.expenseItems);
    final activeShift = _activeShift(dashboard.recentShift, today);
    final activeWork = activeShift == null
        ? null
        : _workForShift(activeShift.workId, analyticsProvider.works);
    final activeWorkName = activeWork?.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: _DashboardHeader(
                  incomeToday: dashboard.incomeToday,
                  orderCount: todayOrders.length,
                  profitToday: dashboard.profitToday,
                  activeShift: activeShift,
                  activeWork: activeWork,
                  activeWorkName: activeWorkName,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(
                      title: 'Tổng quan hôm nay',
                      subtitle: 'Những chỉ số quan trọng nhất trong ngày',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 600
                            ? 4
                            : 2;
                        final spacing = AppSpacing.sm;
                        final itemWidth =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _MetricCard(
                                title: 'Today\'s Revenue',
                                value: MoneyFormatter.format(
                                  dashboard.incomeToday,
                                ),
                                icon: Icons.payments_rounded,
                                accent: AppColors.primary,
                                subtitle: 'Tổng doanh thu hôm nay',
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _MetricCard(
                                title: 'Today\'s Orders',
                                value: '${todayOrders.length}',
                                icon: Icons.receipt_long_rounded,
                                accent: AppColors.secondary,
                                subtitle: 'Số đơn đã ghi nhận',
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _MetricCard(
                                title: 'Today\'s Profit',
                                value: MoneyFormatter.format(
                                  dashboard.profitToday,
                                ),
                                icon: Icons.trending_up_rounded,
                                accent: AppColors.success,
                                subtitle: 'Lợi nhuận ròng',
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _MetricCard(
                                title: 'Active Shift',
                                value: activeShift == null
                                    ? 'No shift'
                                    : 'Live',
                                icon: Icons.work_history_rounded,
                                accent: AppColors.warning,
                                subtitle: activeWork == null
                                    ? 'Chưa có ca hoạt động'
                                    : activeWork.name,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle(
                      title: 'Active Shift',
                      subtitle: 'Ca làm gần nhất và trạng thái hiện tại',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActiveShiftCard(shift: activeShift, work: activeWork),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle(
                      title: 'Quick Actions',
                      subtitle:
                          'Tạo ca, thêm công việc và mở các màn hình chính',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth > 900
                            ? 4
                            : constraints.maxWidth > 600
                            ? 3
                            : 2;
                        final spacing = AppSpacing.sm;
                        final itemWidth =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _ActionCard(
                                icon: Icons.add_circle_outline_rounded,
                                title: '+ New Shift',
                                color: AppColors.primary,
                                onTap: () async {
                                  await context
                                      .read<WorkProvider>()
                                      .loadWorks();
                                  await _openPage(const ShiftFormPage());
                                },
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _ActionCard(
                                icon: Icons.work_outline_rounded,
                                title: '+ New Work',
                                color: AppColors.secondary,
                                onTap: () => _openPage(const WorkFormPage()),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _ActionCard(
                                icon: Icons.bar_chart_rounded,
                                title: 'Analytics',
                                color: AppColors.success,
                                onTap: () => _openPage(const AnalyticsPage()),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _ActionCard(
                                icon: Icons.timeline_rounded,
                                title: 'Timeline',
                                color: AppColors.warning,
                                onTap: () => _openPage(const TimelinePage()),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _ActionCard(
                                icon: Icons.settings_outlined,
                                title: 'Settings',
                                color: AppColors.danger,
                                onTap: () => _openPage(const SettingsPage()),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionTitle(
                      title: 'Mini Charts',
                      subtitle:
                          "Today's income and the last 7 days at a glance",
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 720;
                        final children = [
                          SizedBox(
                            width: isWide
                                ? (constraints.maxWidth - AppSpacing.sm) / 2
                                : constraints.maxWidth,
                            child: _MiniChartCard(
                              title: 'Today\'s income',
                              subtitle: 'Orders created today',
                              color: AppColors.primary,
                              points: _chartPointsFromIncome(todayIncomeItems),
                            ),
                          ),
                          SizedBox(
                            width: isWide
                                ? (constraints.maxWidth - AppSpacing.sm) / 2
                                : constraints.maxWidth,
                            child: _MiniChartCard(
                              title: '7-day income',
                              subtitle: 'Daily totals over the last 7 days',
                              color: AppColors.secondary,
                              points: _chartPointsFromDailyIncome(
                                analyticsProvider.incomeItems,
                              ),
                            ),
                          ),
                        ];

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: children[0]),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: children[1]),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            children[0],
                            const SizedBox(height: AppSpacing.sm),
                            children[1],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RecentSection(
                      title: 'Recent Orders',
                      subtitle: 'Latest income entries from the database',
                      emptyIcon: Icons.receipt_long_outlined,
                      emptyTitle: 'No recent orders',
                      emptySubtitle: 'Add a shift to start tracking orders.',
                      items: recentOrders
                          .map(
                            (income) => _RecentEntryTile(
                              icon: Icons.receipt_long_rounded,
                              accent: AppColors.primary,
                              title: income.title,
                              subtitle: _incomeSubtitle(
                                income,
                                analyticsProvider.shifts,
                                analyticsProvider.works,
                              ),
                              amount: MoneyFormatter.format(
                                income.amount + income.tip,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RecentSection(
                      title: 'Recent Expenses',
                      subtitle: 'Most recent expense records',
                      emptyIcon: Icons.payments_outlined,
                      emptyTitle: 'No recent expenses',
                      emptySubtitle: 'Expense records will appear here.',
                      items: recentExpenses
                          .map(
                            (expense) => _RecentEntryTile(
                              icon: Icons.payments_rounded,
                              accent: AppColors.danger,
                              title: expense.title,
                              subtitle: _expenseSubtitle(
                                expense,
                                analyticsProvider.shifts,
                                analyticsProvider.works,
                              ),
                              amount: MoneyFormatter.format(expense.amount),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await context.read<WorkProvider>().loadWorks();
          await _openPage(const ShiftFormPage());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Shift'),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final double incomeToday;
  final int orderCount;
  final double profitToday;
  final Shift? activeShift;
  final Work? activeWork;
  final String? activeWorkName;

  const _DashboardHeader({
    required this.incomeToday,
    required this.orderCount,
    required this.profitToday,
    required this.activeShift,
    required this.activeWork,
    required this.activeWorkName,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingFor(now.hour);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              20,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, Work Tracker',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Theo dõi doanh thu, đơn hàng và chi phí theo ngày',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hôm nay: ${now.day}/${now.month}/${now.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _HeaderBadge(
                            label: 'Revenue',
                            value: MoneyFormatter.format(incomeToday),
                          ),
                          _HeaderBadge(label: 'Orders', value: '$orderCount'),
                          _HeaderBadge(
                            label: 'Profit',
                            value: MoneyFormatter.format(profitToday),
                          ),
                          _HeaderBadge(
                            label: 'Active',
                            value: activeWorkName == null
                                ? 'No shift'
                                : '$activeWorkName · ${activeShift?.startTime ?? ''} - ${activeShift?.endTime ?? ''}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greetingFor(int hour) {
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftCard extends StatelessWidget {
  final Shift? shift;
  final Work? work;

  const _ActiveShiftCard({required this.shift, required this.work});

  @override
  Widget build(BuildContext context) {
    final currentShift = shift;
    if (currentShift == null) {
      return AppCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.schedule_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có ca hoạt động',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tạo ca mới để bắt đầu theo dõi doanh thu và chi phí.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.work_history_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work?.name ?? 'Active Shift',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currentShift.workDate.day}/${currentShift.workDate.month}/${currentShift.workDate.year}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (work != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          work!.salaryTypeName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ShiftStatTile(
                  label: 'Time',
                  value: '${currentShift.startTime} - ${currentShift.endTime}',
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ShiftStatTile(
                  label: 'Revenue',
                  value: MoneyFormatter.format(currentShift.income),
                  icon: Icons.payments_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ShiftStatTile(
                  label: 'Expense',
                  value: MoneyFormatter.format(currentShift.expense),
                  icon: Icons.remove_circle_outline_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ShiftStatTile(
                  label: 'Profit',
                  value: MoneyFormatter.format(currentShift.profit),
                  icon: Icons.trending_up_rounded,
                ),
              ),
            ],
          ),
          if (currentShift.note.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              currentShift.note,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShiftStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ShiftStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final List<_ChartPoint> points;

  const _MiniChartCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.show_chart_rounded, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 150,
            child: points.isEmpty
                ? const Center(
                    child: Text(
                      'No chart data yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _interval(points),
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.divider.withValues(alpha: 0.65),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.10),
                          ),
                          spots: points
                              .asMap()
                              .entries
                              .map(
                                (entry) => FlSpot(
                                  entry.key.toDouble(),
                                  entry.value.value,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            points.isEmpty ? '0' : MoneyFormatter.format(points.last.value),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  double _interval(List<_ChartPoint> list) {
    final maxValue = list.fold<double>(
      0,
      (sum, point) => sum > point.value ? sum : point.value,
    );
    if (maxValue <= 0) return 1;
    return (maxValue / 3).clamp(1, double.infinity).toDouble();
  }
}

class _RecentSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final List<Widget> items;

  const _RecentSection({
    required this.title,
    required this.subtitle,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(emptyIcon, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emptyTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emptySubtitle,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  items[index],
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 72, endIndent: 16),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentEntryTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String amount;

  const _RecentEntryTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            amount,
            style: TextStyle(color: accent, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;

  const _ChartPoint({required this.label, required this.value});
}

Shift? _activeShift(Shift? shift, DateTime today) {
  if (shift == null) return null;
  final normalizedShift = DateTime(
    shift.workDate.year,
    shift.workDate.month,
    shift.workDate.day,
  );
  final normalizedToday = DateTime(today.year, today.month, today.day);
  if (normalizedShift != normalizedToday) return null;
  return shift;
}

Work? _workForShift(String workId, List<Work> works) {
  try {
    return works.firstWhere((work) => work.id == workId);
  } catch (_) {
    return null;
  }
}

List<Income> _recentIncomeItems(List<Income> incomes) {
  final items = List<Income>.from(incomes)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items.take(3).toList();
}

List<Expense> _recentExpenses(List<Expense> expenses) {
  final items = List<Expense>.from(expenses)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items.take(3).toList();
}

List<Income> _todayIncomeItems(List<Income> incomes, DateTime today) {
  return incomes.where((income) {
    final created = income.createdAt;
    return created.year == today.year &&
        created.month == today.month &&
        created.day == today.day;
  }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

List<Income> _todayOrders(List<Income> incomes, DateTime today) =>
    _todayIncomeItems(incomes, today);

List<_ChartPoint> _chartPointsFromIncome(List<Income> incomes) {
  if (incomes.isEmpty) return const [];
  return incomes
      .map(
        (income) => _ChartPoint(
          label:
              '${income.createdAt.hour.toString().padLeft(2, '0')}:${income.createdAt.minute.toString().padLeft(2, '0')}',
          value: income.amount + income.tip,
        ),
      )
      .toList();
}

List<_ChartPoint> _chartPointsFromDailyIncome(List<Income> incomes) {
  final today = DateTime.now();
  final start = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(const Duration(days: 6));

  final points = <_ChartPoint>[];
  for (var offset = 0; offset < 7; offset++) {
    final date = start.add(Duration(days: offset));
    final total = incomes
        .where((income) {
          final created = income.createdAt;
          return created.year == date.year &&
              created.month == date.month &&
              created.day == date.day;
        })
        .fold<double>(0, (sum, income) => sum + income.amount + income.tip);
    points.add(_ChartPoint(label: '${date.month}/${date.day}', value: total));
  }

  return points;
}

String _incomeSubtitle(Income income, List<Shift> shifts, List<Work> works) {
  final workName = _workNameForShiftId(income.shiftId, shifts, works);
  return '$workName · ${income.createdAt.hour.toString().padLeft(2, '0')}:${income.createdAt.minute.toString().padLeft(2, '0')}';
}

String _expenseSubtitle(Expense expense, List<Shift> shifts, List<Work> works) {
  final workName = _workNameForShiftId(expense.shiftId, shifts, works);
  return '$workName · ${expense.createdAt.hour.toString().padLeft(2, '0')}:${expense.createdAt.minute.toString().padLeft(2, '0')}';
}

String _workNameForShiftId(
  String shiftId,
  List<Shift> shifts,
  List<Work> works,
) {
  try {
    final shift = shifts.firstWhere((shift) => shift.id == shiftId);
    return works.firstWhere((work) => work.id == shift.workId).name;
  } catch (_) {
    return shiftId;
  }
}
