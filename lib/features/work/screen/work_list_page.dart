import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../theme/app_spacing.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../timeline/provider/timeline_provider.dart';
import '../widgets/work_card.dart';
import '../provider/work_provider.dart';
import 'work_detail_page.dart';
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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WorkDetailPage(summary: summary),
                              ),
                            );
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
                            if (!mounted) return;
                            final currentContext = context;
                            if (!currentContext.mounted) return;

                            final dashboardProvider = currentContext
                                .read<DashboardProvider>();
                            final analyticsProvider = currentContext
                                .read<AnalyticsProvider>();
                            final timelineProvider = currentContext
                                .read<TimelineProvider>();

                            final deleteSummary = await provider
                                .getDeleteSummary(summary.work.id);

                            if (!mounted || !currentContext.mounted) {
                              return;
                            }

                            final shouldDelete = await showDialog<bool>(
                              context: currentContext,
                              builder: (dialogContext) {
                                final dialogSummary = deleteSummary;
                                return AlertDialog(
                                  title: const Text('Xoá công việc vĩnh viễn?'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hành động này sẽ xoá ${summary.work.name} cùng toàn bộ ca làm, khoản thu và chi liên quan.',
                                          ),
                                          const SizedBox(height: 12),
                                          _DeleteSummaryRow(
                                            label: 'Ca làm',
                                            value:
                                                '${dialogSummary['shifts'] ?? 0}',
                                          ),
                                          _DeleteSummaryRow(
                                            label: 'Khoản thu',
                                            value:
                                                '${dialogSummary['income'] ?? 0}',
                                          ),
                                          _DeleteSummaryRow(
                                            label: 'Chi phí',
                                            value:
                                                '${dialogSummary['expense'] ?? 0}',
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Không thể hoàn tác sau khi xác nhận.',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                      child: const Text('Xoá vĩnh viễn'),
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

class _DeleteSummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _DeleteSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}
