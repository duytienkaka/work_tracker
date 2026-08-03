enum AnalyticsTimeFilter {
  today,
  sevenDays,
  thirtyDays,
  thisMonth,
  thisYear,
  customRange,
}

extension AnalyticsTimeFilterLabel on AnalyticsTimeFilter {
  String get label {
    switch (this) {
      case AnalyticsTimeFilter.today:
        return 'Today';
      case AnalyticsTimeFilter.sevenDays:
        return '7 Days';
      case AnalyticsTimeFilter.thirtyDays:
        return '30 Days';
      case AnalyticsTimeFilter.thisMonth:
        return 'This Month';
      case AnalyticsTimeFilter.thisYear:
        return 'This Year';
      case AnalyticsTimeFilter.customRange:
        return 'Custom Range';
    }
  }
}
