import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_spacing.dart';
import '../provider/timeline_provider.dart';
import '../widgets/timeline_card.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<TimelineProvider>().loadTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (_, provider, _) {
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                snap: true,
                title: const Text('Dòng thời gian'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Tìm theo ngày hoặc ghi chú',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        context.read<TimelineProvider>().search(value);
                      },
                    ),
                  ),
                ),
              ),
              if (provider.filteredTimeline.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.inbox,
                    title: 'Không tìm thấy dữ liệu',
                    subtitle: 'Thử tìm kiếm theo ngày, công việc hoặc ghi chú',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = provider.filteredTimeline[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TimelineCard(item: item),
                      );
                    }, childCount: provider.filteredTimeline.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
