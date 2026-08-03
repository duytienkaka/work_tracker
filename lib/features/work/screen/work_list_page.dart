import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../theme/app_spacing.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../shift/screen/shift_form_page.dart';
import '../../timeline/provider/timeline_provider.dart';
import '../widgets/work_card.dart';
import '../provider/work_provider.dart';
import 'work_form_page.dart';

class WorkListPage extends StatefulWidget {
  const WorkListPage({super.key});

  @override
  State<WorkListPage> createState() => _WorkListPageState();
}

class _WorkListPageState extends State<WorkListPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<WorkProvider>().loadWorks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Công việc')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm công việc...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<WorkProvider>().search(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SectionTitle(title: 'Danh sách công việc'),
          ),
          Expanded(
            child: provider.filteredWorks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: EmptyState(
                        icon: Icons.work_outline,
                        title: 'Chưa có công việc',
                        subtitle: 'Hãy thêm công việc đầu tiên để bắt đầu.',
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: ListView.builder(
                      key: ValueKey(provider.filteredSummaries.length),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      itemCount: provider.filteredSummaries.length,
                      itemBuilder: (context, index) {
                        final summary = provider.filteredSummaries[index];

                        return WorkCard(
                          summary: summary,
                          onTap: () async {
                            final dashboardProvider = context
                                .read<DashboardProvider>();
                            final analyticsProvider = context
                                .read<AnalyticsProvider>();
                            final timelineProvider = context
                                .read<TimelineProvider>();
                            final currentContext = context;

                            await Navigator.push(
                              currentContext,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ShiftFormPage(work: summary.work),
                              ),
                            );

                            if (!currentContext.mounted) return;
                            if (!mounted) return;
                            await provider.loadWorks();
                            await dashboardProvider.load();
                            await analyticsProvider.load();
                            await timelineProvider.loadTimeline();
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WorkFormPage(work: summary.work),
                              ),
                            );
                          },
                          onDelete: () async {
                            final currentContext = context;
                            final dashboardProvider = currentContext
                                .read<DashboardProvider>();
                            final analyticsProvider = currentContext
                                .read<AnalyticsProvider>();
                            final timelineProvider = currentContext
                                .read<TimelineProvider>();

                            final shouldDelete = await showDialog<bool>(
                              context: currentContext,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text('Xác nhận xoá công việc'),
                                  content: const Text(
                                    'Xoá công việc sẽ đồng thời xoá toàn bộ ca làm và dữ liệu liên quan. Bạn có muốn tiếp tục?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Huỷ'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Xoá'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldDelete != true ||
                                !currentContext.mounted) {
                              return;
                            }

                            try {
                              await provider.deleteWork(summary.work.id);
                              await dashboardProvider.load();
                              await analyticsProvider.load();
                              await timelineProvider.loadTimeline();
                              if (!currentContext.mounted) return;
                              AppFeedback.showSuccess(
                                currentContext,
                                'Công việc và ca làm liên quan đã được xoá.',
                              );
                            } catch (_) {
                              if (!currentContext.mounted) return;
                              AppFeedback.showError(
                                currentContext,
                                'Xoá công việc thất bại. Vui lòng thử lại.',
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkFormPage()),
          );

          await provider.loadWorks();
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
      ),
    );
  }
}
