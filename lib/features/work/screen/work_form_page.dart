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
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final dailyRateController = TextEditingController();
  final hourlyRateController = TextEditingController();

  int salaryType = Work.daily;

  bool get isEdit => widget.work != null;

  bool get isLegacyFixedEditing =>
      isEdit && widget.work!.salaryType == Work.legacyFixed;

  String get salaryRateLabel {
    if (salaryType == Work.daily) return 'Mức lương ngày';
    if (salaryType == Work.hourly) return 'Mức lương giờ';
    return '';
  }

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      nameController.text = widget.work!.name;
      descriptionController.text = widget.work!.description;
      salaryType = widget.work!.salaryType;
      dailyRateController.text = widget.work!.dailyRate.toString();
      hourlyRateController.text = widget.work!.hourlyRate.toString();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    dailyRateController.dispose();
    hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Sửa công việc" : "Thêm công việc")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Tên công việc",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Mô tả",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: salaryType,
              decoration: const InputDecoration(
                labelText: "Loại lương",
                border: OutlineInputBorder(),
              ),
              items: [
                if (isLegacyFixedEditing)
                  const DropdownMenuItem(
                    value: Work.legacyFixed,
                    child: Text("Lương cố định (legacy)"),
                  ),
                const DropdownMenuItem(
                  value: Work.daily,
                  child: Text("Theo ngày"),
                ),
                const DropdownMenuItem(
                  value: Work.hourly,
                  child: Text("Theo giờ"),
                ),
                const DropdownMenuItem(
                  value: Work.freelance,
                  child: Text("Freelance"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  salaryType = value!;
                });
              },
            ),

            const SizedBox(height: 16),
            if (isLegacyFixedEditing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This work is using legacy fixed salary. Choose a new salary type to migrate it.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            if (salaryType == Work.daily || salaryType == Work.hourly)
              Column(
                children: [
                  TextField(
                    controller: salaryType == Work.daily
                        ? dailyRateController
                        : hourlyRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: salaryRateLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            const SizedBox(height: 8),

            PrimaryButton(
              text: isEdit ? "Cập nhật" : "Lưu",
              icon: Icons.save,
              onPressed: () async {
                final currentContext = context;
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  AppFeedback.showError(
                    currentContext,
                    'Tên công việc là bắt buộc.',
                  );
                  return;
                }

                final provider = currentContext.read<WorkProvider>();
                final dailyRate =
                    double.tryParse(dailyRateController.text) ?? 0;
                final hourlyRate =
                    double.tryParse(hourlyRateController.text) ?? 0;

                if (salaryType == Work.daily && dailyRate <= 0) {
                  AppFeedback.showError(
                    currentContext,
                    'Vui lòng nhập mức lương ngày hợp lệ.',
                  );
                  return;
                }

                if (salaryType == Work.hourly && hourlyRate <= 0) {
                  AppFeedback.showError(
                    currentContext,
                    'Vui lòng nhập mức lương giờ hợp lệ.',
                  );
                  return;
                }

                if (isEdit) {
                  await provider.updateWork(
                    widget.work!.copyWith(
                      name: name,
                      description: descriptionController.text.trim(),
                      salaryType: salaryType,
                      dailyRate: dailyRate,
                      hourlyRate: hourlyRate,
                    ),
                  );
                } else {
                  await provider.addWork(
                    name,
                    descriptionController.text.trim(),
                    salaryType,
                    dailyRate,
                    hourlyRate,
                  );
                }

                if (!mounted) return;
                if (!currentContext.mounted) return;
                Navigator.pop(currentContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}
