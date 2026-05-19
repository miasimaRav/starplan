import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _keyTheme = 'selected_theme';
  static const String _keyAvatar = 'selected_avatar';

  String currentTheme = 'default';
  String currentAvatar = 'default';

  // Конфигурация стилей для каждой темы
  static final Map<String, ThemeDataConfig> themeConfigs = {
    'default': ThemeDataConfig(
      background: const Color(0xFF020B3B),
      primary: const Color(0xFFFFC94B),
      cardColor: const Color(0xFF6508E9).withOpacity(0.92),
      textColor: Colors.white,
      isLight: false,
    ),
    'supernova': ThemeDataConfig(
      background: const Color(0xFFF5F6FA), // Чистый светло-серый
      primary: const Color(0xFFFFB300),    // Золотисто-желтый
      cardColor: Colors.white,             // Белоснежные карточки задач
      textColor: const Color(0xFF1E272E),  // Глубокий темный текст
      isLight: true,
    ),
    'space': ThemeDataConfig(
      background: const Color(0xFF000000), // Абсолютно черный (OLED)
      primary: const Color(0xFF00F5D4),    // Кислотно-бирюзовый неон
      cardColor: const Color(0xFF111111),  // Графитовые матовые карточки
      textColor: Colors.white,
      isLight: false,
    ),
  };

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    currentTheme = prefs.getString(_keyTheme) ?? 'default';
    currentAvatar = prefs.getString(_keyAvatar) ?? 'default';
  }

  Future<void> setTheme(String themeKey) async {
    if (!themeConfigs.containsKey(themeKey)) return;
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

// Удобный класс-хелпер для хранения параметров текущей темы
class ThemeDataConfig {
  final Color background;
  final Color primary;
  final Color cardColor;
  final Color textColor;
  final bool isLight;

  ThemeDataConfig({
    required this.background,
    required this.primary,
    required this.cardColor,
    required this.textColor,
    required this.isLight,
  });

  // Создаем системную тему Flutter на основе наших космических цветов
  ThemeData toThemeData() {
    final colorScheme = ColorScheme(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: primary,
      onPrimary: isLight ? Colors.black : Colors.white,
      secondary: primary,
      onSecondary: isLight ? Colors.black : Colors.white,
      error: const Color(0xFFB71359), // AppColors.failed
      onError: Colors.white,
      surface: cardColor,
      onSurface: textColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: cardColor,

      // Стиль для всех текстов в приложении
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor.withOpacity(0.8)),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),

      // Стиль для кнопок, чтобы они не ломали контраст
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isLight ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
