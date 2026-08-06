import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/local_notification_service.dart';
import '../../work/provider/work_provider.dart';

import '../provider/family_provider.dart';
import 'family_workspace_page.dart';

class FamilyAccessPage extends StatefulWidget {
  const FamilyAccessPage({super.key});

  @override
  State<FamilyAccessPage> createState() => _FamilyAccessPageState();
}

class _FamilyAccessPageState extends State<FamilyAccessPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final displayName = TextEditingController();
  bool register = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyProvider>();
    if (provider.isSignedIn) return const FamilyWorkspacePage();
    return Scaffold(
      appBar: AppBar(title: const Text('Family account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(register ? 'Create your account' : 'Sign in to your family', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Keep personal work private and share only what your family needs.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          if (register) ...[
            TextField(controller: displayName, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.person_outline_rounded))),
            const SizedBox(height: 14),
          ],
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 14),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded))),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: provider.isLoading ? null : _submit,
            child: provider.isLoading ? const CircularProgressIndicator() : Text(register ? 'Create account' : 'Sign in'),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Already have an account? Sign in' : 'Need an account? Create one')),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildWorkspace(BuildContext context, FamilyProvider provider) {
    final theme = Theme.of(context);
    final totalExpenses = provider.dashboard?.totalExpense ?? provider.expenses.fold<double>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      appBar: AppBar(title: const Text('Family workspace')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Icon(Icons.cloud_done_rounded, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('You are connected', textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(provider.session?.email ?? 'Family account', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
              Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.onPrimaryContainer, size: 30),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Shared spending', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer)), Text(totalExpenses.toString(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimaryContainer))]),
              const Spacer(),
              IconButton(onPressed: provider.selectedFamily == null ? null : provider.loadExpenses, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
            ])),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: provider.selectedFamily == null ? null : () => _pickDateRange(context), icon: const Icon(Icons.date_range_rounded), label: Text(provider.filterFrom == null ? 'This month' : '${provider.filterFrom!.day}/${provider.filterFrom!.month} - ${provider.filterTo!.day}/${provider.filterTo!.month}'))),
            if (provider.filterFrom != null) IconButton(onPressed: provider.clearDateFilter, icon: const Icon(Icons.clear_rounded), tooltip: 'Clear filter'),
          ]),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: provider.selectedFamily == null ? null : () => _syncWorks(context), icon: const Icon(Icons.sync_rounded), label: const Text('Sync my work to family')),
          if (provider.syncedWorks.isNotEmpty) Text('${provider.syncedWorks.length} personal works synced', style: theme.textTheme.bodySmall),
          const SizedBox(height: 20),
          Text('Shared income', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          OutlinedButton.icon(onPressed: provider.selectedFamily == null ? null : () => _createIncome(context), icon: const Icon(Icons.add_rounded), label: const Text('Add income')),
          if (provider.incomes.isEmpty) const Card(child: ListTile(leading: Icon(Icons.trending_up_rounded), title: Text('No shared income yet')))
          else ...provider.incomes.map((income) => Card(child: ListTile(title: Text(income.title), subtitle: Text('${income.incomeDate.day}/${income.incomeDate.month}/${income.incomeDate.year}'), trailing: Text(income.amount.toString())))),
          const SizedBox(height: 20),
          Text('Monthly budget', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          OutlinedButton.icon(onPressed: provider.selectedFamily == null ? null : () => _saveBudget(context), icon: const Icon(Icons.savings_outlined), label: const Text('Set budget')),
          if (provider.budgets.isEmpty) const Card(child: ListTile(leading: Icon(Icons.savings_outlined), title: Text('No budget set for this month')))
          else ...provider.budgets.map((budget) => Card(child: ListTile(title: Text(budget.category), subtitle: Text('${budget.month}/${budget.year}'), trailing: Text(budget.amount.toString())))),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Categories', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), IconButton(onPressed: provider.selectedFamily == null ? null : () => _createCategory(context), icon: const Icon(Icons.add_rounded), tooltip: 'Add category')]),
          if (provider.categories.isEmpty) const Text('No custom categories yet.') else Wrap(spacing: 8, runSpacing: 8, children: provider.categories.map((category) => Chip(label: Text(category.name))).toList()),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your families', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              IconButton(onPressed: () => _createFamily(context), icon: const Icon(Icons.add_rounded), tooltip: 'Create family'),
            ],
          ),
          if (provider.families.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.family_restroom_rounded, size: 42),
                  const SizedBox(height: 12),
                  const Text('No family workspace yet'),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => _createFamily(context), icon: const Icon(Icons.add_rounded), label: const Text('Create family')),
                ]),
              ),
            )
          else
            ...provider.families.map((family) => Card(color: provider.selectedFamily?.id == family.id ? theme.colorScheme.secondaryContainer : null, child: ListTile(onTap: () => provider.selectFamily(family), leading: const Icon(Icons.family_restroom_rounded), title: Text(family.name), subtitle: Text(provider.selectedFamily?.id == family.id ? 'Selected workspace' : 'Tap to switch'), trailing: const Icon(Icons.chevron_right_rounded)))),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Shared expenses', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            IconButton(onPressed: () => _createExpense(context), icon: const Icon(Icons.add_rounded), tooltip: 'Add expense'),
          ]),
          if (provider.selectedFamily == null)
            const Text('Create or select a family to track shared expenses.')
          else if (provider.expenses.isEmpty)
            Card(child: ListTile(leading: const Icon(Icons.receipt_long_rounded), title: const Text('No shared expenses yet'), subtitle: const Text('Add the first household expense.')))
          else
            ...provider.expenses.map((expense) => Card(child: ListTile(title: Text(expense.title), subtitle: Text('${expense.category} • ${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(expense.amount.toString()), IconButton(onPressed: () => _editExpense(context, expense.id, expense.title, expense.amount), icon: const Icon(Icons.edit_outlined), tooltip: 'Edit'), IconButton(onPressed: () => _deleteExpense(context, expense.id), icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Delete')])))),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: provider.selectedFamily == null ? null : () => _inviteMember(context), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Invite a member')),
          const SizedBox(height: 20),
          Text('Members', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          if (provider.members.isEmpty)
            const Card(child: ListTile(title: Text('No members loaded'), subtitle: Text('Create a family to start adding members.')))
          else
            ...provider.members.map((member) => Card(child: ListTile(leading: CircleAvatar(child: Text(member.displayName.isEmpty ? '?' : member.displayName[0].toUpperCase())), title: Text(member.displayName), subtitle: Text(member.email), trailing: member.role == 'Owner' ? const Icon(Icons.verified_user_rounded) : PopupMenuButton<String>(initialValue: member.role, onSelected: (role) async { try { if (role == 'remove') { await _removeMember(context, member.id, member.displayName); } else { await provider.updateMemberRole(member.id, role); } } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString()))); } }, itemBuilder: (context) => const [PopupMenuItem(value: 'Member', child: Text('Member')), PopupMenuItem(value: 'Editor', child: Text('Editor')), PopupMenuItem(value: 'Viewer', child: Text('Viewer')), PopupMenuDivider(), PopupMenuItem(value: 'remove', child: Text('Remove member'))])))),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: provider.signOut, icon: const Icon(Icons.logout_rounded), label: const Text('Sign out')),
        ],
      ),
    );
  }

  Future<void> _inviteMember(BuildContext context) async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Invite member'), content: TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, emailController.text.trim()), child: const Text('Invite'))]));
    emailController.dispose();
    if (email == null || email.isEmpty || !context.mounted) return;
    try { await context.read<FamilyProvider>().addMember(email); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member invited'))); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> _removeMember(BuildContext context, String memberId, String name) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Remove member?'), content: Text('Remove $name from this family?'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))]));
    if (confirmed != true || !context.mounted) return;
    try { await context.read<FamilyProvider>().removeMember(memberId); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> _deleteExpense(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Delete expense?'), content: const Text('This transaction will be removed from the family history.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
    if (confirmed != true || !context.mounted) return;
    try { await context.read<FamilyProvider>().deleteExpense(id); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<FamilyProvider>();
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDateRange: provider.filterFrom != null ? DateTimeRange(start: provider.filterFrom!, end: provider.filterTo!) : DateTimeRange(start: DateTime(DateTime.now().year, DateTime.now().month, 1), end: DateTime.now()));
    if (range != null) await provider.setDateFilter(range.start, range.end);
  }

  Future<void> _createIncome(BuildContext context) async { final title=TextEditingController(); final amount=TextEditingController(); final result=await showDialog<List<String>>(context:context,builder:(context)=>AlertDialog(title:const Text('Add shared income'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:(){final value=double.tryParse(amount.text.trim());if(title.text.trim().isEmpty||value==null||value<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please enter a title and an amount greater than zero.')));return;}Navigator.pop(context,[title.text.trim(),amount.text.trim()]);},child:const Text('Add'))])); title.dispose();amount.dispose();if(result==null||!context.mounted)return;try{await context.read<FamilyProvider>().createIncome(result[0],double.parse(result[1]));}catch(error){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));}}
  Future<void> _syncWorks(BuildContext context) async { final works=context.read<WorkProvider>().works; try { await context.read<FamilyProvider>().syncWorks(works.map((work)=>{'sourceWorkId':work.id,'workName':work.name,'workType':work.salaryTypeName,'salaryDescription':work.salaryRateDescription}).toList()); await LocalNotificationService.instance.showFamilyUpdate('Your personal work list was synced.'); if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Work synced to family'))); } catch(error){ if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString()))); } }
  Future<void> _saveBudget(BuildContext context) async { final category=TextEditingController(); final amount=TextEditingController(); final result=await showDialog<List<String>>(context:context,builder:(context)=>AlertDialog(title:const Text('Set monthly budget'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:category,decoration:const InputDecoration(labelText:'Category')),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount'))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:(){final value=double.tryParse(amount.text.trim());if(category.text.trim().isEmpty||value==null||value<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Please enter a category and an amount greater than zero.')));return;}Navigator.pop(context,[category.text.trim(),amount.text.trim()]);},child:const Text('Save'))]));category.dispose();amount.dispose();if(result==null||!context.mounted)return;try{await context.read<FamilyProvider>().saveBudget(result[0],double.parse(result[1]));}catch(error){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));}}
  Future<void> _createCategory(BuildContext context) async { final name=TextEditingController(); final value=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:const Text('Add category'),content:TextField(controller:name,decoration:const InputDecoration(labelText:'Category name')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,name.text.trim()),child:const Text('Add'))]));name.dispose();if(value==null||value.isEmpty||!context.mounted)return;try{await context.read<FamilyProvider>().createCategory(value);}catch(error){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));}}

  Future<void> _editExpense(BuildContext context, String id, String currentTitle, double currentAmount) async {
    final title = TextEditingController(text: currentTitle); final amount = TextEditingController(text: currentAmount.toString());
    final result = await showDialog<List<String>>(context: context, builder: (context) => AlertDialog(title: const Text('Edit expense'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')), const SizedBox(height: 12), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { final value = double.tryParse(amount.text.trim()); if (title.text.trim().isNotEmpty && value != null && value > 0) Navigator.pop(context, [title.text.trim(), value.toString()]); }, child: const Text('Save'))]));
    title.dispose(); amount.dispose();
    if (result == null || !context.mounted) return;
    try { await context.read<FamilyProvider>().updateExpense(id, title: result[0], amount: double.parse(result[1]), date: DateTime.now()); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> _createExpense(BuildContext context) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    String? error;
    final result = await showDialog<List<String>>(context: context, builder: (context) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: const Text('Add shared expense'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, autofocus: true, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'What was it for?', hintText: 'Groceries, electricity...')),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', suffixText: 'đ')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Align(alignment: Alignment.centerLeft, child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)))),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { final parsed = double.tryParse(amount.text.trim()); if (title.text.trim().isEmpty) { setState(() => error = 'Please enter an expense title.'); return; } if (parsed == null || parsed <= 0) { setState(() => error = 'Enter an amount greater than zero.'); return; } Navigator.pop(context, [title.text.trim(), parsed.toString()]); }, child: const Text('Add'))],
      );
    }));
    title.dispose(); amount.dispose();
    if (result == null || result[0].isEmpty || double.tryParse(result[1]) == null || !context.mounted) return;
    try { await context.read<FamilyProvider>().createExpense(title: result[0], category: 'Other', amount: double.parse(result[1]), date: DateTime.now()); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense added'))); } catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', '')))); }
  }

  Future<void> _createFamily(BuildContext context) async {
    final name = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Create family'),
      content: TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Family name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, name.text.trim()), child: const Text('Create'))],
    ));
    name.dispose();
    if (value == null || value.isEmpty || !context.mounted) return;
    try {
      await context.read<FamilyProvider>().createFamily(value);
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _submit() async {
    try {
      final provider = context.read<FamilyProvider>();
      if (register) {
        await provider.signUp(email.text.trim(), password.text, displayName.text.trim());
      } else {
        await provider.signIn(email.text.trim(), password.text);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected to family workspace')));
    } catch (error) {
      if (mounted) {
        final message = error.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 5)));
      }
    }
  }
}
