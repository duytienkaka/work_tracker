import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../../expense/model/expense_model.dart';
import '../../expense/provider/expense_provider.dart';
import '../../expense/widgets/expense_card.dart';
import '../../income/model/income_model.dart';
import '../../income/provider/income_provider.dart';
import '../../income/widgets/income_card.dart';
import '../../work/model/work_model.dart';
import '../model/shift_model.dart';
import '../provider/shift_provider.dart';
import 'shift_form_page.dart';

class ShiftDetailPage extends StatefulWidget {
  final Work? work;
  final Shift? shift;

  const ShiftDetailPage({super.key, this.work, this.shift});

  @override
  State<ShiftDetailPage> createState() => _ShiftDetailPageState();
}

class _ShiftDetailPageState extends State<ShiftDetailPage> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasLoaded) return;
    _hasLoaded = true;

    Future.microtask(() {
      if (!mounted) return;
      final shift = widget.shift;
      if (shift != null) {
        context.read<IncomeProvider>().loadByShift(shift.id);
        context.read<ExpenseProvider>().loadByShift(shift.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final work = widget.work;

    return Scaffold(
      appBar: AppBar(
        title: shift == null
            ? Text(work?.name ?? 'Chi tiết ca làm')
            : Hero(
                tag: _heroTag(shift.id),
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    work?.name ?? 'Chi tiết ca làm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        actions: [
          if (shift != null) ...[
            Builder(
              builder: (context) {
                return IconButton(
                  tooltip: 'Chỉnh sửa ca làm',
                  onPressed: () async {
                    final shiftProvider = context.read<ShiftProvider>();
                    final incomeProvider = context.read<IncomeProvider>();
                    final expenseProvider = context.read<ExpenseProvider>();

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftFormPage(work: work, shift: shift),
                      ),
                    );
                    if (!mounted) return;
                    await shiftProvider.load();
                    await incomeProvider.loadByShift(shift.id);
                    await expenseProvider.loadByShift(shift.id);
                  },
                  icon: const Icon(Icons.edit_outlined),
                );
              },
            ),
          ],
        ],
      ),
      body: shift == null
          ? const Center(child: Text('Không có dữ liệu ca làm'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummarySection(),
                const SizedBox(height: 16),
                _buildShiftInformationSection(shift, work),
                const SizedBox(height: 16),
                _buildIncomeSection(),
                const SizedBox(height: 16),
                _buildExpenseSection(),
              ],
            ),
    );
  }

  String _heroTag(String shiftId) => 'shift-hero-$shiftId';

  Widget _buildSummarySection() {
    return _SectionCard(
      title: 'Summary',
      child: Consumer2<IncomeProvider, ExpenseProvider>(
        builder: (context, incomeProvider, expenseProvider, _) {
          final summary = context.read<ShiftProvider>().buildSummary(
            incomes: incomeProvider.incomes,
            expenses: expenseProvider.expenses,
          );
          final profitColor = summary.profit >= 0
              ? AppColors.success
              : AppColors.danger;

          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                _SummaryMetricTile(
                  label: 'Total Orders',
                  value: summary.incomeCount.toString(),
                  color: AppColors.primary,
                  icon: Icons.receipt_long_rounded,
                ),
                _SummaryMetricTile(
                  label: 'Total Income',
                  value: summary.totalIncome.toStringAsFixed(0),
                  color: AppColors.primary,
                  icon: Icons.arrow_upward_rounded,
                ),
                _SummaryMetricTile(
                  label: 'Total Tips',
                  value: summary.totalTip.toStringAsFixed(0),
                  color: AppColors.success,
                  icon: Icons.tips_and_updates_outlined,
                ),
                _SummaryMetricTile(
                  label: 'Total Expense',
                  value: summary.totalExpense.toStringAsFixed(0),
                  color: AppColors.danger,
                  icon: Icons.arrow_downward_rounded,
                ),
                _SummaryMetricTile(
                  label: 'Net Profit',
                  value: summary.profit.toStringAsFixed(0),
                  color: profitColor,
                  icon: summary.profit >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  valuePrefix: summary.profit >= 0 ? '+' : '',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftInformationSection(Shift shift, Work? work) {
    return _SectionCard(
      title: 'Shift Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Công việc', value: work?.name ?? 'N/A'),
          _InfoRow(
            label: 'Ngày làm',
            value: shift.workDate.toString().substring(0, 10),
          ),
          _InfoRow(
            label: 'Giờ bắt đầu',
            value: shift.startTime.isEmpty ? '---' : shift.startTime,
          ),
          _InfoRow(
            label: 'Giờ kết thúc',
            value: shift.endTime.isEmpty ? '---' : shift.endTime,
          ),
          _InfoRow(
            label: 'Ghi chú',
            value: shift.note.isEmpty ? '---' : shift.note,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection() {
    return _SectionCard(
      title: 'Income',
      child: Consumer<IncomeProvider>(
        builder: (context, provider, _) {
          final incomes = provider.incomes;

          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: incomes.isEmpty
                  ? Column(
                      key: const ValueKey('income-empty'),
                      children: [
                        const EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Chưa có đơn hàng',
                          subtitle:
                              'Thêm đơn hàng để bắt đầu theo dõi doanh thu.',
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FloatingActionButton.extended(
                            heroTag: 'add-income-${widget.shift?.id ?? 'none'}',
                            onPressed: () => _showIncomeFormSheet(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Income'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: ValueKey('income-list-${incomes.length}'),
                      children: [
                        ...incomes.map(
                          (income) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: ValueKey('income-${income.id}'),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  await _showIncomeFormSheet(
                                    context,
                                    income: income,
                                  );
                                  return false;
                                }

                                if (direction == DismissDirection.endToStart) {
                                  await _confirmDeleteIncome(context, income);
                                  return false;
                                }

                                return false;
                              },
                              background: _SwipeBackground(
                                alignment: Alignment.centerLeft,
                                color: AppColors.success,
                                icon: Icons.edit_rounded,
                                label: 'Edit',
                              ),
                              secondaryBackground: _SwipeBackground(
                                alignment: Alignment.centerRight,
                                color: AppColors.danger,
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                              ),
                              child: IncomeCard(
                                income: income,
                                onTap: () => _showIncomeFormSheet(
                                  context,
                                  income: income,
                                ),
                                onLongPress: () =>
                                    _confirmDeleteIncome(context, income),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FloatingActionButton.extended(
                            heroTag: 'add-income-${widget.shift?.id ?? 'none'}',
                            onPressed: () => _showIncomeFormSheet(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Income'),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpenseSection() {
    return _SectionCard(
      title: 'Expense',
      child: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final expenses = provider.expenses;

          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: expenses.isEmpty
                  ? Column(
                      key: const ValueKey('expense-empty'),
                      children: [
                        const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Chưa có chi phí',
                          subtitle:
                              'Thêm chi phí để theo dõi khoản chi của ca làm.',
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FloatingActionButton.extended(
                            heroTag:
                                'add-expense-${widget.shift?.id ?? 'none'}',
                            onPressed: () => _showExpenseFormSheet(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: ValueKey('expense-list-${expenses.length}'),
                      children: [
                        ...expenses.map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: ValueKey('expense-${expense.id}'),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  await _showExpenseFormSheet(
                                    context,
                                    expense: expense,
                                  );
                                  return false;
                                }

                                if (direction == DismissDirection.endToStart) {
                                  await _confirmDeleteExpense(context, expense);
                                  return false;
                                }

                                return false;
                              },
                              background: _SwipeBackground(
                                alignment: Alignment.centerLeft,
                                color: AppColors.success,
                                icon: Icons.edit_rounded,
                                label: 'Edit',
                              ),
                              secondaryBackground: _SwipeBackground(
                                alignment: Alignment.centerRight,
                                color: AppColors.danger,
                                icon: Icons.delete_rounded,
                                label: 'Delete',
                              ),
                              child: ExpenseCard(
                                expense: expense,
                                onTap: () => _showExpenseFormSheet(
                                  context,
                                  expense: expense,
                                ),
                                onLongPress: () =>
                                    _confirmDeleteExpense(context, expense),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FloatingActionButton.extended(
                            heroTag:
                                'add-expense-${widget.shift?.id ?? 'none'}',
                            onPressed: () => _showExpenseFormSheet(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense'),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showIncomeFormSheet(
    BuildContext context, {
    Income? income,
  }) async {
    final isEdit = income != null;
    final provider = context.read<IncomeProvider>();
    final shift = widget.shift;
    if (shift == null) return;

    final titleController = TextEditingController(text: income?.title ?? '');
    final amountController = TextEditingController(
      text: income == null ? '' : income.amount.toString(),
    );
    final tipController = TextEditingController(
      text: income == null ? '0' : income.tip.toString(),
    );
    final noteController = TextEditingController(text: income?.note ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Income' : 'Add Income',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tipController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Tip',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final amount = double.tryParse(amountController.text);
                          final tip = double.tryParse(tipController.text) ?? 0;

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Title is required.'),
                              ),
                            );
                            return;
                          }

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Amount must be greater than 0.'),
                              ),
                            );
                            return;
                          }

                          if (tip < 0) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Tip cannot be negative.'),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(sheetContext, true);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;
    final tip = double.tryParse(tipController.text) ?? 0;
    final note = noteController.text.trim();
    final currentIncome = income;

    if (currentIncome != null) {
      await provider.updateIncome(
        currentIncome.copyWith(
          title: title,
          amount: amount,
          tip: tip,
          note: note,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await provider.addIncome(
        Income(
          id: const Uuid().v4(),
          shiftId: shift.id,
          title: title,
          amount: amount,
          tip: tip,
          note: note,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _showExpenseFormSheet(
    BuildContext context, {
    Expense? expense,
  }) async {
    final isEdit = expense != null;
    final provider = context.read<ExpenseProvider>();
    final shift = widget.shift;
    if (shift == null) return;

    final titleController = TextEditingController(text: expense?.title ?? '');
    final amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toString(),
    );
    final noteController = TextEditingController(text: expense?.note ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Expense' : 'Add Expense',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final amount = double.tryParse(amountController.text);

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Title is required.'),
                              ),
                            );
                            return;
                          }

                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Amount must be greater than 0.'),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(sheetContext, true);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text) ?? 0;
    final note = noteController.text.trim();
    final currentExpense = expense;

    if (currentExpense != null) {
      await provider.updateExpense(
        currentExpense.copyWith(
          title: title,
          amount: amount,
          note: note,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await provider.addExpense(
        Expense(
          id: const Uuid().v4(),
          shiftId: shift.id,
          title: title,
          amount: amount,
          note: note,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _confirmDeleteIncome(BuildContext context, Income income) async {
    final provider = context.read<IncomeProvider>();
    final shift = widget.shift;
    if (shift == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete income?'),
          content: Text('Delete "${income.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await provider.deleteIncome(income.id, shift.id);
  }

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    Expense expense,
  ) async {
    final provider = context.read<ExpenseProvider>();
    final shift = widget.shift;
    if (shift == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete expense?'),
          content: Text('Delete "${expense.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await provider.deleteExpense(expense.id, shift.id);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String valuePrefix;

  const _SummaryMetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.valuePrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valuePrefix$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
