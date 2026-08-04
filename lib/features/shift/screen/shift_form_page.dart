import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_colors.dart';
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

  TimeOfDay? startTime;

  TimeOfDay? endTime;

  Work? selectedWork;
  List<Work> availableWorks = [];

  final noteController = TextEditingController();

  String get formattedDuration {
    if (selectedWork == null) return '---';
    if (selectedWork!.salaryType != Work.hourly) return '---';
    if (startTime == null) return 'Chưa có';
    if (endTime == null) return 'Chưa có';
    final start = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
      startTime!.hour,
      startTime!.minute,
    );
    final end = DateTime(
      workDate.year,
      workDate.month,
      workDate.day,
      endTime!.hour,
      endTime!.minute,
    );
    final duration = end.difference(start);
    if (duration.isNegative) return 'Không hợp lệ';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  bool get isHourly => selectedWork?.salaryType == Work.hourly;
  bool get isDaily => selectedWork?.salaryType == Work.daily;
  bool get isFreelance => selectedWork?.salaryType == Work.freelance;

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
      if (start.length == 2) {
        startTime = TimeOfDay(
          hour: int.parse(start[0]),
          minute: int.parse(start[1]),
        );
      }

      if (widget.shift!.endTime.isNotEmpty) {
        final end = widget.shift!.endTime.split(":");
        if (end.length == 2) {
          endTime = TimeOfDay(
            hour: int.parse(end[0]),
            minute: int.parse(end[1]),
          );
        }
      }

      noteController.text = widget.shift!.note;
    }
  }

  @override
  void dispose() {
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
      initialTime: startTime ?? const TimeOfDay(hour: 8, minute: 0),
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
      initialTime: endTime ?? startTime ?? const TimeOfDay(hour: 8, minute: 0),
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

          const SizedBox(height: 8),
          if (selectedWork != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedWork!.salaryTypeName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (selectedWork!.salaryRateDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      selectedWork!.salaryRateDescription,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                if (selectedWork!.hasSalaryRate)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      selectedWork!.salaryType == Work.hourly
                          ? (startTime != null && endTime != null
                                ? 'Lương dự kiến: ${MoneyFormatter.format(selectedWork!.computeSalaryForShift(startDateTime: DateTime(workDate.year, workDate.month, workDate.day, startTime!.hour, startTime!.minute), endDateTime: DateTime(workDate.year, workDate.month, workDate.day, endTime!.hour, endTime!.minute)))}'
                                : 'Lương dự kiến: Chưa đủ dữ liệu')
                          : 'Lương dự kiến: ${MoneyFormatter.format(selectedWork!.computeSalaryForShift(startDateTime: DateTime(workDate.year, workDate.month, workDate.day, 0, 0), endDateTime: null))}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
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
            subtitle: Text(
              startTime != null ? startTime!.format(context) : 'Chưa có',
            ),
            trailing: startTime != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        startTime = null;
                      });
                    },
                  )
                : null,
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

          if (isHourly) ...[
            const SizedBox(height: 16),
            _InfoRow(label: 'Thời lượng đã làm', value: formattedDuration),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Thu nhập lương và chi phí sẽ được quản lý ở màn hình chi tiết ca làm sau khi lưu.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
              final currentContext = context;

              if (selectedWork == null) {
                AppFeedback.showError(
                  currentContext,
                  'Vui lòng chọn công việc.',
                );
                return;
              }

              if (selectedWork!.salaryType == Work.hourly ||
                  selectedWork!.salaryType == Work.daily) {
                if (startTime == null) {
                  AppFeedback.showError(
                    currentContext,
                    'Bạn cần nhập giờ bắt đầu.',
                  );
                  return;
                }

                if (endTime == null) {
                  AppFeedback.showError(
                    currentContext,
                    'Bạn cần nhập giờ kết thúc.',
                  );
                  return;
                }

                final start = DateTime(
                  workDate.year,
                  workDate.month,
                  workDate.day,
                  startTime!.hour,
                  startTime!.minute,
                );
                final end = DateTime(
                  workDate.year,
                  workDate.month,
                  workDate.day,
                  endTime!.hour,
                  endTime!.minute,
                );

                if (!end.isAfter(start)) {
                  AppFeedback.showError(
                    currentContext,
                    'Giờ kết thúc phải sau giờ bắt đầu.',
                  );
                  return;
                }
              }

              final provider = currentContext.read<ShiftProvider>();
              final existingShifts = provider.shifts.where((item) {
                if (item.workId != selectedWork!.id) return false;
                if (item.workDate != workDate) return false;
                if (isEdit && item.id == widget.shift?.id) return false;
                return true;
              }).toList();

              if (selectedWork!.salaryType != Work.freelance &&
                  startTime != null &&
                  endTime != null) {
                final newStart = DateTime(
                  workDate.year,
                  workDate.month,
                  workDate.day,
                  startTime!.hour,
                  startTime!.minute,
                );
                final newEnd = DateTime(
                  workDate.year,
                  workDate.month,
                  workDate.day,
                  endTime!.hour,
                  endTime!.minute,
                );

                for (final existing in existingShifts) {
                  if (existing.startDateTime == null ||
                      existing.endDateTime == null) {
                    continue;
                  }

                  final existingStart = existing.startDateTime!;
                  final existingEnd = existing.endDateTime!;
                  final overlap =
                      newStart.isBefore(existingEnd) &&
                      newEnd.isAfter(existingStart);
                  if (overlap) {
                    AppFeedback.showError(
                      currentContext,
                      'Ca làm bị trùng với một ca khác.',
                    );
                    return;
                  }
                }
              }

              final shift = Shift(
                id: isEdit ? widget.shift!.id : const Uuid().v4(),
                workId: selectedWork!.id,
                workDate: workDate,
                startTime: startTime != null
                    ? "${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}"
                    : '',
                endTime: endTime != null
                    ? "${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}"
                    : '',
                income: 0,
                expense: 0,
                note: noteController.text,
              );

              final dashboardProvider = currentContext
                  .read<DashboardProvider>();
              final analyticsProvider = currentContext
                  .read<AnalyticsProvider>();
              final timelineProvider = currentContext.read<TimelineProvider>();
              final workProvider = currentContext.read<WorkProvider>();

              try {
                if (isEdit) {
                  await provider.update(shift);
                } else {
                  await provider.add(shift);
                }

                if (!mounted || !currentContext.mounted) return;
                AppFeedback.showSuccess(
                  currentContext,
                  isEdit ? 'Ca làm đã được cập nhật.' : 'Ca làm đã được tạo.',
                );

                await dashboardProvider.load();
                await analyticsProvider.load();
                await timelineProvider.loadTimeline();
                await workProvider.loadWorks();

                if (!mounted || !currentContext.mounted) return;
                Navigator.pop(currentContext);
              } catch (_) {
                if (!mounted || !currentContext.mounted) return;
                if (currentContext.mounted) {
                  AppFeedback.showError(
                    currentContext,
                    'Không thể lưu ca làm.',
                  );
                }
              }
            },
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
