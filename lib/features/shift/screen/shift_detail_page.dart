import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../../expense/model/expense_model.dart';
import '../../expense/provider/expense_provider.dart';
import '../../expense/widgets/expense_card.dart';
import '../../income/model/income_model.dart';
import '../../income/provider/income_provider.dart';
import '../../income/widgets/income_card.dart';
import '../../work/model/work_model.dart';
import '../../../core/services/salary_engine.dart';
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
  Widget build(BuildContext context) {
    final work = widget.work;
    final shift = widget.shift;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ca làm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Sửa ca làm',
            onPressed: shift == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftFormPage(work: work, shift: shift),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Xóa ca làm',
            onPressed: shift == null
                ? null
                : () => _confirmDeleteShift(context, shift),
          ),
        ],
      ),
      body: shift == null
          ? const Center(child: Text('Không có dữ liệu ca làm'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummarySection(shift, work),
                const SizedBox(height: 16),
                _buildShiftInformationSection(shift, work),
                const SizedBox(height: 16),
                _buildIncomeSection(),
                const SizedBox(height: 16),
                _buildExpenseSection(),
              ],
            ),
      floatingActionButton: null,
    );
  }

  Widget _buildSummarySection(Shift shift, Work? work) {
    return _SectionCard(
      title: 'Tóm tắt',
      child: Consumer2<IncomeProvider, ExpenseProvider>(
        builder: (context, incomeProvider, expenseProvider, _) {
          final summary = context.read<ShiftProvider>().buildSummary(
            work:
                work ??
                Work(
                  id: shift.workId,
                  name: shift.workId,
                  description: '',
                  salaryType: Work.legacyFixed,
                  dailyRate: 0,
                  hourlyRate: 0,
                  color: 0,
                  icon: 0,
                  isActive: true,
                  createdAt: DateTime.now(),
                ),
            shift: shift,
            incomes: incomeProvider.incomes,
            expenses: expenseProvider.expenses,
          );

          final profitColor = summary.profit >= 0
              ? AppColors.success
              : AppColors.danger;

          final tiles = <Widget>[
            _SummaryMetricTile(
              label: 'Số đơn',
              value: summary.incomeCount.toString(),
              color: AppColors.primary,
              icon: Icons.receipt_long_rounded,
            ),
            _SummaryMetricTile(
              label: 'Tổng thu',
              value: MoneyFormatter.format(summary.totalIncome),
              color: AppColors.primary,
              icon: Icons.arrow_upward_rounded,
            ),
            _SummaryMetricTile(
              label: 'Tip',
              value: MoneyFormatter.format(summary.totalTip),
              color: AppColors.success,
              icon: Icons.tips_and_updates_outlined,
            ),
            _SummaryMetricTile(
              label: 'Tổng chi',
              value: MoneyFormatter.format(summary.totalExpense),
              color: AppColors.danger,
              icon: Icons.arrow_downward_rounded,
            ),
            _SummaryMetricTile(
              label: 'Lợi nhuận',
              value: MoneyFormatter.format(summary.profit),
              color: profitColor,
              icon: summary.profit >= 0
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              valuePrefix: summary.profit >= 0 ? '+' : '',
            ),
          ];

          return AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 12.0;
                final tileWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: tiles
                      .map((w) => SizedBox(width: tileWidth, child: w))
                      .toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftInformationSection(Shift shift, Work? work) {
    return _SectionCard(
      title: 'Thông tin ca làm',
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
          if (work != null && work.hasSalaryRate)
            _InfoRow(
              label: 'Lương theo công việc',
              value: MoneyFormatter.format(
                work.computeSalaryForShift(
                  startDateTime:
                      shift.startDateTime ??
                      DateTime(
                        shift.workDate.year,
                        shift.workDate.month,
                        shift.workDate.day,
                        0,
                        0,
                      ),
                  endDateTime: shift.endDateTime,
                ),
              ),
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
      title: 'Thu nhập',
      child: Consumer<IncomeProvider>(
        builder: (context, provider, _) {
          final incomes = provider.incomes;
          final salaryIncomes = incomes
              .where(
                (income) =>
                    income.generated ||
                    SalaryEngine.isSalaryIncomeId(income.id),
              )
              .toList();
          final manualIncomes = incomes
              .where(
                (income) =>
                    !(income.generated ||
                        SalaryEngine.isSalaryIncomeId(income.id)),
              )
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (salaryIncomes.isNotEmpty) ...[
                const Text(
                  'Lương tự động',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ...salaryIncomes.map((income) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      elevation: 0,
                      color: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.payments_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(income.title),
                        subtitle: const Text('Tạo tự động từ lương ca làm'),
                        trailing: Text(
                          MoneyFormatter.format(income.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 6),
              ],
              const Text(
                'Thu nhập khác',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (manualIncomes.isEmpty)
                Column(
                  children: [
                    const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Chưa có đơn hàng',
                      subtitle: 'Thêm đơn hàng thủ công để theo dõi doanh thu.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton.extended(
                        heroTag: 'add-income-${widget.shift?.id ?? 'none'}',
                        onPressed: () => _showIncomeFormSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm thu nhập'),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    ...manualIncomes.map((income) {
                      return Padding(
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
                            onTap: () =>
                                _showIncomeFormSheet(context, income: income),
                            onLongPress: () =>
                                _confirmDeleteIncome(context, income),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton.extended(
                        heroTag: 'add-income-${widget.shift?.id ?? 'none'}',
                        onPressed: () => _showIncomeFormSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm thu nhập'),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseSection() {
    return _SectionCard(
      title: 'Chi phí',
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
                            label: const Text('Thêm chi phí'),
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
                            label: const Text('Thêm chi phí'),
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
                  isEdit ? 'Sửa thu nhập' : 'Thêm thu nhập',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên',
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
                    labelText: 'Số tiền',
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
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Huỷ'),
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
                            AppFeedback.showError(
                              sheetContext,
                              'Tên khoản thu là bắt buộc.',
                            );
                            return;
                          }

                          if (amount == null || amount <= 0) {
                            AppFeedback.showError(
                              sheetContext,
                              'Số tiền phải lớn hơn 0.',
                            );
                            return;
                          }

                          if (tip < 0) {
                            AppFeedback.showError(
                              sheetContext,
                              'Tip không được âm.',
                            );
                            return;
                          }

                          Navigator.pop(sheetContext, true);
                        },
                        child: const Text('Lưu'),
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

    final currentContext = context;

    try {
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

      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showSuccess(
        currentContext,
        currentIncome != null
            ? 'Đơn hàng đã được cập nhật.'
            : 'Đơn hàng đã được thêm.',
      );
    } catch (_) {
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showError(currentContext, 'Không thể lưu đơn hàng.');
    }
  }

  Future<void> _showExpenseFormSheet(
    BuildContext context, {
    Expense? expense,
  }) async {
    final currentContext = context;
    final isEdit = expense != null;
    final provider = currentContext.read<ExpenseProvider>();
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
                  isEdit ? 'Sửa chi phí' : 'Thêm chi phí',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tên',
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
                    labelText: 'Số tiền',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('Huỷ'),
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

    try {
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

      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showSuccess(
        currentContext,
        currentExpense != null
            ? 'Chi phí đã được cập nhật.'
            : 'Chi phí đã được thêm.',
      );
    } catch (_) {
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showError(currentContext, 'Không thể lưu chi phí.');
    }
  }

  Future<void> _confirmDeleteIncome(BuildContext context, Income income) async {
    final currentContext = context;
    final provider = currentContext.read<IncomeProvider>();
    final shift = widget.shift;
    if (shift == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xoá khoản thu?'),
          content: Text('Xoá "${income.title}"?'),
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

    try {
      await provider.deleteIncome(income.id, shift.id);
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showSuccess(currentContext, 'Đơn hàng đã được xoá.');
    } catch (_) {
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showError(currentContext, 'Không thể xoá đơn hàng.');
    }
  }

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    Expense expense,
  ) async {
    final currentContext = context;
    final provider = currentContext.read<ExpenseProvider>();
    final shift = widget.shift;
    if (shift == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xoá chi phí?'),
          content: Text('Xoá "${expense.title}"?'),
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

    try {
      await provider.deleteExpense(expense.id, shift.id);
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showSuccess(currentContext, 'Chi phí đã được xoá.');
    } catch (_) {
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showError(currentContext, 'Không thể xoá chi phí.');
    }
  }

  Future<void> _confirmDeleteShift(BuildContext context, Shift shift) async {
    final currentContext = context;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa ca làm?'),
          content: const Text(
            'Bạn có chắc muốn xóa ca này?\n\n'
            'Việc này sẽ xóa:\n'
            '• Shift\n'
            '• Income\n'
            '• Expense\n\n'
            'Không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final provider = currentContext.read<ShiftProvider>();
      await provider.delete(shift.id, shift.workId);
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showSuccess(currentContext, 'Ca làm đã được xóa.');
      Navigator.pop(currentContext);
    } catch (_) {
      if (!mounted || !currentContext.mounted) return;
      AppFeedback.showError(currentContext, 'Không thể xóa ca làm.');
    }
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
