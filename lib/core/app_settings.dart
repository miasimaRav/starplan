import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _keyTheme = 'selected_theme';
  static const String _keyAvatar = 'selected_avatar';

  // Текущие настройки
  String currentTheme = 'default';
  String currentAvatar = 'default';

  // Доступные темы
  final Map<String, Color> themeBackgrounds = {
    'default': const Color(0xFF020B3B),
    'dark': const Color(0xFF0A0F2E),
    'space': const Color(0xFF0B0014),
  };

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    currentTheme = prefs.getString(_keyTheme) ?? 'default';
    currentAvatar = prefs.getString(_keyAvatar) ?? 'default';
  }

  Future<void> setTheme(String themeKey) async {
    if (!themeBackgrounds.containsKey(themeKey)) return;
    currentTheme = themeKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, themeKey);
  }

  Future<void> setAvatar(String avatarKey) async {
    currentAvatar = avatarKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatar, avatarKey);
  }
}