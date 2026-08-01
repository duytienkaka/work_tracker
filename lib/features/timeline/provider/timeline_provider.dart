import 'package:flutter/material.dart';

import '../model/timeline_item.dart';
import '../repository/timeline_repository.dart';

class TimelineProvider extends ChangeNotifier {
  final repository = TimelineRepository();

  List<TimelineItem> timeline = [];
  List<TimelineItem> filteredTimeline = [];

  Future<void> loadTimeline() async {
    timeline = await repository.getTimeline();
    filteredTimeline = List.from(timeline);
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadTimeline();
  }

  void search(String keyword) {
    keyword = keyword.trim().toLowerCase();

    if (keyword.isEmpty) {
      filteredTimeline = List.from(timeline);
      notifyListeners();
      return;
    }

    filteredTimeline = timeline.where((day) {
      if (day.date.toLowerCase().contains(keyword)) {
        return true;
      }

      for (final shift in day.shifts) {
        if (shift.note.toLowerCase().contains(keyword)) {
          return true;
        }

        if (shift.workId.toLowerCase().contains(keyword)) {
          return true;
        }
      }

      return false;
    }).toList();

    notifyListeners();
  }

  void toggle(String date) {
    final index = timeline.indexWhere((e) => e.date == date);
    if (index == -1) return;

    timeline[index].isExpanded = !timeline[index].isExpanded;
    notifyListeners();
  }
}
