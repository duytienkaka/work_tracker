import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                ? const EmptyState(
                    icon: Icons.work_outline,
                    title: 'Chưa có công việc',
                    subtitle: 'Hãy thêm công việc đầu tiên để bắt đầu.',
                  )
                : ListView.builder(
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
                              builder: (_) => ShiftFormPage(work: summary.work),
                            ),
                          );
                          await provider.loadWorks();
                          await context.read<DashboardProvider>().load();
                          await context.read<AnalyticsProvider>().load();
                          await context.read<TimelineProvider>().loadTimeline();
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkFormPage(work: summary.work),
                            ),
                          );
                        },
                        onDelete: () async {
                          await provider.deleteWork(summary.work.id);
                        },
                      );
                    },
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
