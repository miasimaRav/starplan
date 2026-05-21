import 'package:flutter/material.dart';

import '../core/app_settings.dart';

class ThemeProvider extends ChangeNotifier {
  final AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  ThemeData get currentThemeData {
    final config = AppSettings.themeConfigs[_settings.currentTheme]
        ?? AppSettings.themeConfigs['default']!;
    return config.toThemeData();
  }

  Future<void> init() async {
    await _settings.loadSettings();
    notifyListeners();
  }

  Future<void> changeTheme(String themeKey) async {
    await _settings.setTheme(themeKey);
    notifyListeners(); // Этот вызов заставит ВСЕ экраны перерисоваться
  }
}
