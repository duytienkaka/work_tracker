import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/shift_template.dart';

class ShiftTemplateService {
  static const _key = 'shift_templates';

  Future<List<ShiftTemplate>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_key) ?? [];
    return raw
        .map((value) => ShiftTemplate.fromJson(jsonDecode(value)))
        .toList();
  }

  Future<void> save(ShiftTemplate template) async {
    final preferences = await SharedPreferences.getInstance();
    final templates = await load();
    templates.removeWhere((item) => item.id == template.id);
    templates.insert(0, template);
    await preferences.setStringList(
      _key,
      templates.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> delete(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final templates = await load()..removeWhere((item) => item.id == id);
    await preferences.setStringList(
      _key,
      templates.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
