import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/primary_button.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../timeline/provider/timeline_provider.dart';
import '../../work/model/work_model.dart';
import '../../work/provider/work_provider.dart';
import '../model/shift_model.dart';
import '../provider/shift_provider.dart';

class ShiftFormPage extends StatefulWidget {
  final Work? work;
  final Shift? shift;

  const ShiftFormPage({super.key, this.work, this.shift});

  @override
  State<ShiftFormPage> createState() => _ShiftFormPageState();
}

class _ShiftFormPageState extends State<ShiftFormPage> {
  DateTime workDate = DateTime.now();

  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);

  TimeOfDay? endTime;

  Work? selectedWork;
  List<Work> availableWorks = [];

  final incomeController = TextEditingController();

  final expenseController = TextEditingController();

  final noteController = TextEditingController();

  bool get isEdit => widget.shift != null;

  @override
  void initState() {
    super.initState();

    availableWorks = context.read<WorkProvider>().works;
    if (isEdit) {
      final found = availableWorks.where(
        (work) => work.id == widget.shift!.workId,
      );
      selectedWork = found.isNotEmpty
          ? found.first
          : widget.work ??
                (availableWorks.isNotEmpty ? availableWorks.first : null);
    } else {
      selectedWork =
          widget.work ??
          (availableWorks.isNotEmpty ? availableWorks.first : null);
    }

    if (isEdit) {
      workDate = widget.shift!.workDate;

      final start = widget.shift!.startTime.split(":");
      startTime = TimeOfDay(
        hour: int.parse(start[0]),
        minute: int.parse(start[1]),
      );

      if (widget.shift!.endTime.isNotEmpty) {
        final end = widget.shift!.endTime.split(":");
        endTime = TimeOfDay(hour: int.parse(end[0]), minute: int.parse(end[1]));
      }

      incomeController.text = widget.shift!.income.toString();

      expenseController.text = widget.shift!.expense.toString();

      noteController.text = widget.shift!.note;
    }
  }

  @override
  void dispose() {
    incomeController.dispose();
    expenseController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: workDate,
    );

    if (result != null) {
      setState(() {
        workDate = result;
      });
    }
  }

  Future<void> pickStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (result != null) {
      setState(() {
        startTime = result;
      });
    }
  }

  Future<void> pickEndTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: endTime ?? startTime,
    );

    if (result != null) {
      setState(() {
        endTime = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Sửa ca làm" : "Thêm ca làm")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<Work>(
            initialValue: selectedWork,
            decoration: const InputDecoration(
              labelText: "Công việc",
              border: OutlineInputBorder(),
            ),
            items: availableWorks
                .map(
                  (work) =>
                      DropdownMenuItem(value: work, child: Text(work.name)),
                )
                .toList(),
            onChanged: (work) {
              setState(() {
                selectedWork = work;
              });
            },
          ),

          const SizedBox(height: 16),

          ListTile(
            title: const Text("Ngày làm"),
            subtitle: Text(workDate.toString().substring(0, 10)),
            trailing: const Icon(Icons.calendar_month),
            onTap: pickDate,
          ),

          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text("Giờ bắt đầu"),
            subtitle: Text(startTime.format(context)),
            onTap: pickStartTime,
          ),

          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.access_time_filled),
            title: const Text("Giờ kết thúc"),
            subtitle: Text(
              endTime != null ? endTime!.format(context) : 'Chưa có',
            ),
            trailing: endTime != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        endTime = null;
                      });
                    },
                  )
                : null,
            onTap: pickEndTime,
          ),

          const SizedBox(height: 16),

          TextField(
            controller: incomeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: const InputDecoration(labelText: "Thu nhập"),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: expenseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            decoration: const InputDecoration(labelText: "Chi phí"),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Ghi chú"),
          ),

          const SizedBox(height: 30),

          PrimaryButton(
            text: isEdit ? "Cập nhật" : "Lưu",
            icon: Icons.save,
            onPressed: () async {
              if (selectedWork == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng chọn công việc.')),
                );
                return;
              }

              final shift = Shift(
                id: isEdit ? widget.shift!.id : const Uuid().v4(),
                workId: selectedWork!.id,
                workDate: workDate,
                startTime:
                    "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}",
                endTime: endTime != null
                    ? "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}"
                    : '',
                income: double.tryParse(incomeController.text) ?? 0,
                expense: double.tryParse(expenseController.text) ?? 0,
                note: noteController.text,
              );

              final provider = context.read<ShiftProvider>();
              final dashboardProvider = context.read<DashboardProvider>();
              final analyticsProvider = context.read<AnalyticsProvider>();
              final timelineProvider = context.read<TimelineProvider>();
              final workProvider = context.read<WorkProvider>();

              if (isEdit) {
                await provider.update(shift);
              } else {
                await provider.add(shift);
              }

              if (!mounted) return;
              await dashboardProvider.load();
              await analyticsProvider.load();
              await timelineProvider.loadTimeline();
              await workProvider.loadWorks();
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
