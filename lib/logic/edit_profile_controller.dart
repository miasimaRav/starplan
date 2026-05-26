import 'package:flutter/material.dart';
import '../../core/app_settings.dart';
import '../../data/database.dart';

/// Контроллер для управления логикой редактирования профиля пользователя.
/// Отвечает за загрузку данных, валидацию полей ввода и сохранение в БД.
class EditProfileController extends ChangeNotifier {
  String currentAvatar = 'default';
  Map<String, dynamic>? _userRow;
  bool isLoading = true; // Флаг для показа индикатора загрузки

  // Контроллеры текстовых полей перенесены в логику, так как именно логика
  // считывает из них данные для сохранения и валидации.
  final nameController = TextEditingController();
  final registerDateController = TextEditingController();
  final birthdayController = TextEditingController();
  final emailController = TextEditingController();
  final levelController = TextEditingController();
  final starsController = TextEditingController();

  // Коллбэки для связи со слоем UI (позволяют контроллеру управлять навигацией и снекбарами)
  void Function(String message)? onError;
  void Function()? onSuccess;

  Future<void> loadUser() async {
    final row = await DatabaseHelper.instance.getCurrentUser();
    if (row == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    final reg = row['registration_date'] as String;
    final regDate = DateTime.tryParse(reg);

    // Загружаем аватар
    final settings = AppSettings();
    await settings.loadSettings();

    _userRow = row;
    currentAvatar = settings.currentAvatar;
    nameController.text = row['name'] as String? ?? 'User';
    registerDateController.text = regDate != null
        ? '${regDate.day.toString().padLeft(2, '0')}.${regDate.month.toString().padLeft(2, '0')}.${regDate.year}'
        : '';
    birthdayController.text = row['birth_date'] as String? ?? '';
    emailController.text = row['email'] as String? ?? '';
    levelController.text = (row['level'] ?? 1).toString();
    starsController.text = (row['stars'] ?? 100).toString();

    isLoading = false;
    notifyListeners(); // Сообщаем UI, что данные готовы к отрисовке
  }

  Future<void> saveProfile() async {
    if (_userRow == null) {
      onSuccess?.call(); // Если нет пользователя, просто закрываем экран
      return;
    }

    final emailStr = emailController.text.trim();
    final birthdayStr = birthdayController.text.trim();

    // 1. ПРОВЕРКА EMAIL (если поле не пустое)
    if (emailStr.isNotEmpty) {
      // Паттерн: строка@строка.строка (от 2 до 4 символов в домене)
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(emailStr)) {
        onError?.call('Пожалуйста, введите корректный email (например, user@mail.com)');
        return; // Прерываем сохранение
      }
    }

    // 2. ПРОВЕРКА ДАТЫ РОЖДЕНИЯ (если поле не пустое)
    if (birthdayStr.isNotEmpty) {
      // Паттерн: строгий формат ДД.ММ.ГГГГ с проверкой адекватности чисел (01-31.01-12.XXXX)
      final dateRegex = RegExp(r'^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.\d{4}$');
      if (!dateRegex.hasMatch(birthdayStr)) {
        onError?.call('Пожалуйста, введите дату в формате ДД.ММ.ГГГГ');
        return; // Прерываем сохранение
      }
    }

    final id = _userRow!['id'] as int;
    final name = nameController.text.trim();
    final level = int.tryParse(levelController.text.trim()) ?? 1;

    // Вызов сохранения в БД
    await DatabaseHelper.instance.updateUser(
      id: id,
      name: name,
      birthDate: birthdayStr.isEmpty ? null : birthdayStr,
      email: emailStr.isEmpty ? null : emailStr,
      level: level,
    );

    onSuccess?.call(); // Сигнализируем UI об успешном сохранении
  }

  @override
  void dispose() {
    // Обязательно очищаем контроллеры во избежание утечек памяти
    nameController.dispose();
    registerDateController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    levelController.dispose();
    starsController.dispose();
    super.dispose();
  }
}