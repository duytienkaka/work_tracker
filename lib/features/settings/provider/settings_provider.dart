import 'package:flutter/material.dart';

import '../model/currency_option.dart';
import '../repository/settings_repository.dart';

enum AppThemeMode { system, light, dark }

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository repository;

  AppThemeMode themeMode = AppThemeMode.system;
  CurrencyOption currency = CurrencyOption.vnd;

  SettingsProvider(this.repository);

  ThemeMode get currentThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Future<void> loadSettings() async {
    themeMode = await repository.getThemeMode();
    currency = await repository.getCurrency();
    notifyListeners();
  }

  Future<void> updateThemeMode(AppThemeMode value) async {
    themeMode = value;
    await repository.saveThemeMode(value);
    notifyListeners();
  }

  Future<void> updateCurrency(CurrencyOption value) async {
    currency = value;
    await repository.saveCurrency(value);
    notifyListeners();
  }
}
