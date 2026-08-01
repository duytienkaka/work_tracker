import 'package:flutter/material.dart';

import '../model/dashboard_model.dart';
import '../repository/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository repository;

  DashboardProvider(this.repository);

  DashboardModel? dashboard;

  Future<void> load() async {
    dashboard = await repository.load();

    notifyListeners();
  }
}
