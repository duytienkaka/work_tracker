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
      if (mounted) context.read<TimelineProvider>().loadTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimelineProvider>(
      builder: (context, provider, _) {
        final colors = Theme.of(context).colorScheme;
        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                title: const Text('Timeline'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: 'Search shifts, work, or notes',
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: provider.search,
                    ),
                  ),
                ),
              ),
              if (provider.filteredTimeline.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: EmptyState(
                        icon: Icons.timeline_rounded,
                        title: 'No timeline entries',
                        subtitle: 'Completed shifts will appear here.',
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TimelineCard(
                          item: provider.filteredTimeline[index],
                        ),
                      ),
                      childCount: provider.filteredTimeline.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
