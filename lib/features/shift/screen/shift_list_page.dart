import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_title.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../work/model/work_model.dart';
import '../../work/provider/work_provider.dart';
import '../model/shift_model.dart';
import '../provider/shift_provider.dart';
import 'shift_form_page.dart';

class ShiftListPage extends StatefulWidget {
  final Work? work;

  const ShiftListPage({super.key, this.work});

  @override
  State<ShiftListPage> createState() => _ShiftListPageState();
}

class _ShiftListPageState extends State<ShiftListPage> {
  String query = '';
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasLoaded) return;
    _hasLoaded = true;

    Future.microtask(() {
      if (!mounted) return;
      if (widget.work != null) {
        context.read<ShiftProvider>().load(widget.work!.id);
      } else {
        context.read<ShiftProvider>().load();
      }
      context.read<WorkProvider>().loadWorks();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.work != null) {
      final provider = context.watch<ShiftProvider>();

      return Scaffold(
        appBar: AppBar(title: Text(widget.work!.name)),
        body: RefreshIndicator(
          onRefresh: () async {
            await provider.load(widget.work!.id);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tóm tắt ca làm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummary(
                      'Tổng thu',
                      provider.totalIncome,
                      AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildSummary(
                      'Tổng chi',
                      provider.totalExpense,
                      AppColors.danger,
                    ),
                    const SizedBox(height: 8),
                    _buildSummary(
                      'Lợi nhuận',
                      provider.totalProfit,
                      AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SectionTitle(title: 'Danh sách ca làm'),
              if (provider.shifts.isEmpty)
                const EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Chưa có ca làm nào',
                  subtitle: 'Hãy thêm ca làm đầu tiên cho công việc này.',
                )
              else
                ...provider.shifts.map((shift) {
                  final work =
                      widget.work ??
                      Work(
                        id: shift.workId,
                        name: shift.workId,
                        description: '',
                        salaryType: 0,
                        color: 0,
                        icon: 0,
                        isActive: true,
                        createdAt: DateTime.now(),
                      );
                  return _buildShiftCard(shift, work);
                }),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShiftFormPage(work: widget.work!),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm ca làm'),
        ),
      );
    }

    final provider = context.watch<ShiftProvider>();
    final workProvider = context.read<WorkProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tất cả ca làm')),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.load();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tất cả ca làm',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Tìm kiếm ca làm'),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm ca làm...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      query = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: provider.shifts.isEmpty
                      ? const EmptyState(
                          icon: Icons.schedule_outlined,
                          title: 'Chưa có ca làm nào',
                          subtitle: 'Thêm ca làm mới để bắt đầu.',
                        )
                      : ListView(
                          children: provider.shifts
                              .where((shift) {
                                final searchText =
                                    '${shift.workId} ${shift.workDate.toString().substring(0, 10)} ${shift.startTime} ${shift.endTime}'
                                        .toLowerCase();
                                return query.isEmpty ||
                                    searchText.contains(query);
                              })
                              .map((shift) {
                                final work = workProvider.works.firstWhere(
                                  (item) => item.id == shift.workId,
                                  orElse: () => Work(
                                    id: shift.workId,
                                    name: shift.workId,
                                    description: '',
                                    salaryType: 0,
                                    color: 0,
                                    icon: 0,
                                    isActive: true,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                                return _buildShiftCard(shift, work);
                              })
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(String title, double value, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard(Shift shift, Work work) {
    return AppCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShiftFormPage(work: work, shift: shift),
          ),
        );
        await context.read<ShiftProvider>().load();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shift.workDate.toString().substring(0, 10),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Ca làm',
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label:
                    '${shift.startTime} → ${shift.endTime.isEmpty ? '---' : shift.endTime}',
                icon: Icons.access_time_rounded,
              ),
              _Chip(label: work.name, icon: Icons.work_outline_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ValueTile(
                  label: 'Thu nhập',
                  value: shift.income.toStringAsFixed(0),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ValueTile(
                  label: 'Chi phí',
                  value: shift.expense.toStringAsFixed(0),
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lợi nhuận: ${shift.profit.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (shift.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(shift.note, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ValueTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final bool visible;

  const _ShiftTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
