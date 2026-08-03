import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../shift/model/shift_model.dart';
import '../model/work_model.dart';
import '../model/work_summary.dart';
import '../repository/work_repository.dart';

class WorkProvider extends ChangeNotifier {
  final WorkRepository repository;

  WorkProvider(this.repository);

  List<Work> works = [];
  List<Work> filteredWorks = [];
  List<WorkSummary> summaries = [];
  List<WorkSummary> _searchSummaries = [];
  List<Shift> currentWorkShifts = [];
  String? currentWorkDetailId;

  List<WorkSummary> get filteredSummaries => _searchSummaries;

  Future<void> loadWorks() async {
    works = await repository.getAllWorks();
    summaries = await repository.getWorkSummary();
    filteredWorks = List.from(works);
    _searchSummaries = List.from(summaries);

    notifyListeners();
  }

  Future<void> addWork(
    String name,
    String description,
    int salaryType,
    double dailyRate,
    double hourlyRate,
  ) async {
    final work = Work(
      id: const Uuid().v4(),
      name: name,
      description: description,
      salaryType: salaryType,
      dailyRate: dailyRate,
      hourlyRate: hourlyRate,
      color: Colors.blue.toARGB32(),
      icon: Icons.work.codePoint,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await repository.insertWork(work);

    await loadWorks();
  }

  Future<void> updateWork(Work work) async {
    await repository.updateWork(work);

    await loadWorks();
  }

  Future<void> deleteWork(String id) async {
    await repository.deleteWork(id);

    await loadWorks();
  }

  Future<void> loadWorkDetail(String workId) async {
    currentWorkDetailId = workId;
    currentWorkShifts = await repository.getShiftsByWork(workId);
    notifyListeners();
  }

  Future<void> refreshCurrentWorkDetail() async {
    if (currentWorkDetailId == null) return;
    await loadWorkDetail(currentWorkDetailId!);
  }

  Future<WorkSummary> getSummary(String id) {
    return repository.getSummary(id);
  }

  void search(String keyword) {
    if (keyword.trim().isEmpty) {
      filteredWorks = List.from(works);
      _searchSummaries = summaries;
    } else {
      filteredWorks = works.where((work) {
        return work.name.toLowerCase().contains(keyword.toLowerCase());
      }).toList();

      _searchSummaries = summaries.where((summary) {
        return summary.work.name.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    }

    notifyListeners();
  }
}
