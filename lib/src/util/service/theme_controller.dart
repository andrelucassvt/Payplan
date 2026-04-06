import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static const _key = 'themeMode';
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    themeMode.value = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> toggle(BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final isDark = themeMode.value == ThemeMode.dark ||
        (themeMode.value == ThemeMode.system && brightness == Brightness.dark);
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'light' : 'dark');
  }

  static bool isDark(BuildContext context) {
    if (themeMode.value == ThemeMode.system) {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }
}
