import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  int salaryType = 0;

  bool get isEdit => widget.work != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      nameController.text = widget.work!.name;
      descriptionController.text = widget.work!.description;
      salaryType = widget.work!.salaryType;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
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
              items: const [
                DropdownMenuItem(value: 0, child: Text("Lương cố định")),
                DropdownMenuItem(value: 1, child: Text("Theo ngày")),
                DropdownMenuItem(value: 2, child: Text("Theo giờ")),
                DropdownMenuItem(value: 3, child: Text("Freelance")),
              ],
              onChanged: (value) {
                setState(() {
                  salaryType = value!;
                });
              },
            ),

            const SizedBox(height: 24),

            PrimaryButton(
              text: isEdit ? "Cập nhật" : "Lưu",
              icon: Icons.save,
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final provider = context.read<WorkProvider>();

                if (isEdit) {
                  await provider.updateWork(
                    widget.work!.copyWith(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      salaryType: salaryType,
                    ),
                  );
                } else {
                  await provider.addWork(
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                    salaryType,
                  );
                }

                if (!context.mounted) return;
                if (!mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
