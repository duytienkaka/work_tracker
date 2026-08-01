import 'package:shared_preferences/shared_preferences.dart';

import '../model/currency_option.dart';
import '../provider/settings_provider.dart';

class SettingsRepository {
  static const _themeKey = 'settings_theme_mode';
  static const _currencyKey = 'settings_currency';

  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeKey);

    switch (raw) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  Future<void> saveThemeMode(AppThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value.name);
  }

  Future<CurrencyOption> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currencyKey);

    switch (raw) {
      case 'usd':
        return CurrencyOption.usd;
      case 'eur':
        return CurrencyOption.eur;
      default:
        return CurrencyOption.vnd;
    }
  }

  Future<void> saveCurrency(CurrencyOption value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, value.code);
  }
}
