import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeStorage {
  static const _themeKey = 'norma.theme_mode';

  Future<ThemeMode> load() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themeKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> save(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _themeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
