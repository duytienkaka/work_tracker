class AppRefreshCoordinator {
  Future<void> refreshAfterCrud({
    required Future<void> Function() refreshShift,
    required Future<void> Function() refreshDashboard,
    required Future<void> Function() refreshAnalytics,
    required Future<void> Function() refreshWork,
    required Future<void> Function() refreshTimeline,
  }) async {
    await Future.wait([
      refreshShift(),
      refreshDashboard(),
      refreshAnalytics(),
      refreshWork(),
      refreshTimeline(),
    ]);
  }
}
