import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _keyTheme = 'selected_theme';
  static const String _keyAvatar = 'selected_avatar';

  String currentTheme = 'default';
  String currentAvatar = 'default';
  static const String _keyTrophy = 'selected_trophy';
  String currentTrophy = 'none'; // По умолчанию кубка нет

  // Конфигурация стилей для каждой темы
  static final Map<String, ThemeDataConfig> themeConfigs = {
    'default': ThemeDataConfig(
      background: const Color(0xFF020B3B),
      primary: const Color(0xFFFFC94B),
      cardColor: const Color(0xFF6510A9).withOpacity(0.92),
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
    currentTrophy = prefs.getString(_keyTrophy) ?? 'none';
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

  Future<void> setTrophy(String trophyKey) async {
    currentTrophy = trophyKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTrophy, trophyKey);
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

  // Создаем системную тему Flutter на основе космических цветов
  ThemeData toThemeData() {
    final colorScheme = ColorScheme(
      brightness: isLight ? Brightness.light : Brightness.dark,
      primary: primary,
      onPrimary: Colors.black, // Черный текст на акцентных кнопках всегда читается лучше
      secondary: primary,
      onSecondary: Colors.black,
      error: const Color(0xFFB71359),
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
          foregroundColor: Colors.black, // Жестко задаем черный текст на кнопках
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: cardColor, // Фон окна берет цвет карточки текущей темы
        headerBackgroundColor: primary, // Шапка берет золотой/бирюзовый цвет
        headerForegroundColor: Colors.black, // Текст в шапке всегда черный для контраста

        // Настройка цвета дней
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary; // Кружок выбранного дня
          }
          return Colors.transparent;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black; // Цифра внутри выбранного кружка
          }
          return textColor; // Цифры остальных дней подстраиваются под светлую/темную тему
        }),

        // Цвет текущего дня (сегодня), если он не выбран
        todayForegroundColor: WidgetStateProperty.all(primary),

        // Кнопки "ОК" и "Отмена"
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: primary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: primary),
      ),
    );
  }
}
