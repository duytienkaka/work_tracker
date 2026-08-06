// ignore_for_file: curly_braces_in_flow_control_structures, unnecessary_to_list_in_spreads, unused_element
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/family_provider.dart';
import '../../work/provider/work_provider.dart';

class FamilyWorkspacePage extends StatelessWidget {
  const FamilyWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FamilyProvider>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(provider.selectedFamily?.name ?? 'Family workspace'),
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'), Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Transactions'), Tab(icon: Icon(Icons.people_outline), text: 'Members'), Tab(icon: Icon(Icons.work_outline), text: 'Work')]),
          actions: [IconButton(onPressed: provider.signOut, icon: const Icon(Icons.logout_rounded), tooltip: 'Sign out')],
        ),
        body: const TabBarView(children: [_OverviewTab(), _TransactionsTab(), _MembersTab(), _SharedWorkTab()]),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget { const _OverviewTab(); @override Widget build(BuildContext context) { final p=context.watch<FamilyProvider>(); final d=p.dashboard; return ListView(padding:const EdgeInsets.all(20),children:[Text('Family overview',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:16),Card(child:ListTile(leading:const Icon(Icons.trending_down_rounded),title:const Text('This month spending'),trailing:Text((d?.totalExpense??0).toString()))),Card(child:ListTile(leading:const Icon(Icons.receipt_long_rounded),title:const Text('Transactions'),trailing:Text('${d?.transactionCount??0}'))),Card(child:ListTile(leading:const Icon(Icons.savings_outlined),title:const Text('Budgets'),trailing:Text('${p.budgets.length}'))),Card(child:ListTile(leading:const Icon(Icons.trending_up_rounded),title:const Text('Shared income'),trailing:Text('${p.incomes.length}'))) ]); } }
class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<FamilyProvider>();
    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Transaction history', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...p.expenses.map((e) => Card(child: ListTile(title: Text(e.title), subtitle: Text(e.category), trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _delete(context, e.id))))).toList(),
        ...p.incomes.map((i) => Card(child: ListTile(title: Text(i.title), subtitle: const Text('Income'), trailing: Text(i.amount.toString())))).toList(),
      ]),
      floatingActionButton: PopupMenuButton<String>(icon: const Icon(Icons.add_rounded), onSelected: (value) => _add(context, value), itemBuilder: (context) => const [PopupMenuItem(value: 'expense', child: Text('Add expense')), PopupMenuItem(value: 'income', child: Text('Add income'))]),
    );
  }
  Future<void> _delete(BuildContext context, String id) async { final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete transaction?'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))])); if (ok == true && context.mounted) await context.read<FamilyProvider>().deleteExpense(id); }
  Future<void> _edit(BuildContext context, String id, String oldTitle, double oldAmount) async { final t = TextEditingController(text: oldTitle); final a = TextEditingController(text: oldAmount.toString()); final r = await showDialog<List<String>>(context: context, builder: (c) => AlertDialog(title: const Text('Edit transaction'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'Title')), TextField(controller: a, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount'))]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), FilledButton(onPressed: () { final n = double.tryParse(a.text); if (t.text.trim().isNotEmpty && n != null && n > 0) Navigator.pop(c, [t.text.trim(), a.text]); }, child: const Text('Save'))])); t.dispose(); a.dispose(); if (r != null && context.mounted) await context.read<FamilyProvider>().updateExpense(id, title: r[0], amount: double.parse(r[1]), date: DateTime.now()); }
  Future<void> _add(BuildContext context, String type) async { final title = TextEditingController(); final amount = TextEditingController(); final result = await showDialog<List<String>>(context: context, builder: (context) => AlertDialog(title: Text(type == 'expense' ? 'Add expense' : 'Add income'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')), TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { final n = double.tryParse(amount.text); if (title.text.trim().isEmpty || n == null || n <= 0) return; Navigator.pop(context, [title.text.trim(), amount.text]); }, child: const Text('Create'))])); title.dispose(); amount.dispose(); if (result == null || !context.mounted) return; final n = double.parse(result[1]); if (type == 'expense') await context.read<FamilyProvider>().createExpense(title: result[0], category: 'Other', amount: n, date: DateTime.now()); else await context.read<FamilyProvider>().createIncome(result[0], n); }
}
class _MembersTab extends StatelessWidget { const _MembersTab(); @override Widget build(BuildContext context) { final p=context.watch<FamilyProvider>(); return Scaffold(body:ListView(padding:const EdgeInsets.all(16),children:[Text('Family members',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:12),...p.members.map((m)=>Card(child:ListTile(leading:const Icon(Icons.person_outline_rounded),title:Text(m.displayName),subtitle:Text(m.email),trailing:m.role=='Owner'?const Icon(Icons.verified_user_outlined):PopupMenuButton<String>(onSelected:(v)async{if(v=='remove'){await p.removeMember(m.id);}else{await p.updateMemberRole(m.id,v);}},itemBuilder:(c)=>const [PopupMenuItem(value:'Editor',child:ListTile(leading:Icon(Icons.edit_outlined),title:Text('Editor'))),PopupMenuItem(value:'Viewer',child:ListTile(leading:Icon(Icons.visibility_outlined),title:Text('Viewer'))),PopupMenuItem(value:'remove',child:ListTile(leading:Icon(Icons.person_remove_outlined),title:Text('Remove')))]))))]),floatingActionButton:FloatingActionButton(onPressed:()=>_invite(context),child:const Icon(Icons.person_add_alt_1_rounded))); } Future<void> _invite(BuildContext context) async { final email=TextEditingController();final value=await showDialog<String>(context:context,builder:(context)=>AlertDialog(title:const Text('Add member'),content:TextField(controller:email,decoration:const InputDecoration(labelText:'Registered email')),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,email.text.trim()),child:const Text('Add'))]));email.dispose();if(value!=null&&value.isNotEmpty&&context.mounted)await context.read<FamilyProvider>().addMember(value); } }
class _SharedWorkTab extends StatelessWidget { const _SharedWorkTab(); @override Widget build(BuildContext context) { final p=context.watch<FamilyProvider>(); return Scaffold(body:ListView(padding:const EdgeInsets.all(16),children:[Text('Shared work',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:12),if(p.syncedWorks.isEmpty)const Card(child:ListTile(title:Text('No synced work yet'),subtitle:Text('Sync your personal work.'))) else ...p.syncedWorks.map((w)=>Card(child:ListTile(leading:const Icon(Icons.work_outline_rounded),title:Text(w.workName),subtitle:Text('${w.workType} • ${w.salaryDescription}'))))]),floatingActionButton:FloatingActionButton.extended(onPressed:()async{final works=context.read<WorkProvider>().works;await p.syncWorks(works.map((w)=>{'sourceWorkId':w.id,'workName':w.name,'workType':w.salaryTypeName,'salaryDescription':w.salaryRateDescription}).toList());},icon:const Icon(Icons.sync_rounded),label:const Text('Sync work'))); } }
