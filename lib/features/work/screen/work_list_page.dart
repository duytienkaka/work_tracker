import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_spacing.dart';
import '../provider/work_provider.dart';
import '../widgets/work_card.dart';
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
      if (mounted) context.read<WorkProvider>().loadWorks();
    });
  }

  Future<void> _newWork() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkFormPage()),
    );
    if (mounted) context.read<WorkProvider>().loadWorks();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Works'),
        actions: [
          IconButton(
            tooltip: 'Add work',
            onPressed: _newWork,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.loadWorks,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '${provider.filteredSummaries.length} work spaces',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  onChanged: provider.search,
                  decoration: InputDecoration(
                    hintText: 'Search your work',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            if (provider.filteredSummaries.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: EmptyState(
                      icon: Icons.workspaces_outline,
                      title: 'No work spaces yet',
                      subtitle: 'Create a work space to start tracking shifts.',
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final summary = provider.filteredSummaries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: WorkCard(
                          summary: summary,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkDetailPage(summary: summary),
                              ),
                            );
                            if (mounted) provider.loadWorks();
                          },
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkFormPage(work: summary.work),
                              ),
                            );
                            if (mounted) provider.loadWorks();
                          },
                          onDelete: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete this work?'),
                                content: Text(
                                  'All shifts and entries for ${summary.work.name} will be removed.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !mounted) return;
                            try {
                              await provider.deleteWork(summary.work.id);
                              if (mounted) AppFeedback.showSuccess(context, 'Work deleted');
                            } catch (_) {
                              if (mounted) AppFeedback.showError(context, 'Could not delete work');
                            }
                          },
                        ),
                      );
                    },
                    childCount: provider.filteredSummaries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newWork,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New work'),
      ),
    );
  }
}
