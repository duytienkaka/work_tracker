import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/primary_button.dart';
import '../model/work_model.dart';
import '../provider/work_provider.dart';

class WorkFormPage extends StatefulWidget {
  final Work? work;
  const WorkFormPage({super.key, this.work});

  @override
  State<WorkFormPage> createState() => _WorkFormPageState();
}

class _WorkFormPageState extends State<WorkFormPage> {
  final name = TextEditingController();
  final description = TextEditingController();
  final dailyRate = TextEditingController();
  final hourlyRate = TextEditingController();
  int type = Work.daily;

  bool get editing => widget.work != null;

  @override
  void initState() {
    super.initState();
    final work = widget.work;
    if (work != null) {
      name.text = work.name;
      description.text = work.description;
      dailyRate.text = work.dailyRate.toString();
      hourlyRate.text = work.hourlyRate.toString();
      type = work.salaryType;
    }
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    dailyRate.dispose();
    hourlyRate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit work' : 'New work')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Set up your work space', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Only the details needed to calculate your shifts.', style: TextStyle(color: colors.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextField(controller: name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Work name', prefixIcon: Icon(Icons.work_outline_rounded))),
          const SizedBox(height: 14),
          TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.notes_rounded))),
          const SizedBox(height: 24),
          Text('How are you paid?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(value: Work.hourly, label: Text('Hourly'), icon: Icon(Icons.schedule_rounded)),
              ButtonSegment(value: Work.daily, label: Text('Daily'), icon: Icon(Icons.today_rounded)),
              ButtonSegment(value: Work.freelance, label: Text('Freelance'), icon: Icon(Icons.design_services_rounded)),
            ],
            selected: {type == Work.legacyFixed ? Work.daily : type},
            onSelectionChanged: (value) => setState(() => type = value.first),
          ),
          const SizedBox(height: 20),
          if (type == Work.hourly)
            TextField(controller: hourlyRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Hourly rate', prefixIcon: Icon(Icons.payments_outlined))),
          if (type == Work.daily)
            TextField(controller: dailyRate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Daily rate', prefixIcon: Icon(Icons.payments_outlined))),
          const SizedBox(height: 28),
          PrimaryButton(text: editing ? 'Save changes' : 'Create work', icon: Icons.check_rounded, onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final contextNow = context;
    final workName = name.text.trim();
    if (workName.isEmpty) {
      AppFeedback.showError(contextNow, 'Enter a work name');
      return;
    }
    final daily = double.tryParse(dailyRate.text) ?? 0;
    final hourly = double.tryParse(hourlyRate.text) ?? 0;
    if (type == Work.daily && daily <= 0) {
      AppFeedback.showError(contextNow, 'Enter a valid daily rate');
      return;
    }
    if (type == Work.hourly && hourly <= 0) {
      AppFeedback.showError(contextNow, 'Enter a valid hourly rate');
      return;
    }

    final provider = contextNow.read<WorkProvider>();
    if (editing) {
      await provider.updateWork(widget.work!.copyWith(name: workName, description: description.text.trim(), salaryType: type, dailyRate: daily, hourlyRate: hourly));
    } else {
      await provider.addWork(workName, description.text.trim(), type, daily, hourly);
    }
    if (mounted) Navigator.pop(contextNow);
  }
}
