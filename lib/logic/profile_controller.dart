import 'package:flutter/material.dart';
import '../../core/app_settings.dart';
import '../../data/database.dart'; // Подключаем DatabaseHelper

/// Контроллер для управления логикой профиля пользователя.
/// Отделен от UI для соблюдения принципа Separation of Concerns.
class ProfileController extends ChangeNotifier {
  // Данные пользователя из БД
  String userName = 'User';
  int userLevel = 1;
  int userStars = 100;
  int totalXP = 0;
  int tasksCompleted = 0;
  int currentStreak = 0;
  int streakRecord = 0;
  bool _achievementsChecked = false;
  int xpForNextLevel = 500;
  int currentLevelXP = 0;
  double progressFraction = 0.0;
  String currentAvatar = 'default';
  String currentTrophy = 'none';

  // Коллбэк для передачи события в UI (чтобы показать SnackBar)
  void Function(String title, int reward)? onAchievementUnlocked;

  // Достижения (теперь обращаются к переменным контроллера)
  late List<Map<String, dynamic>> achievements = [
    {
      'title': 'Первый шаг',
      'subtitle': 'Выполните первую задачу',
      'condition': () => tasksCompleted >= 1,
      'starsReward': 20,
      'completed': false,
      'date': '--',
      'iconPath': 'assets/images/icons/achievement_first_step.png',
      'key': 'first_step'
    },
    {
      'title': 'Огненная полоса',
      'subtitle': 'Достигните 7 дней подряд',
      'condition': () => currentStreak >= 7,
      'starsReward': 20,
      'completed': false,
      'date': '--',
      'iconPath': 'assets/images/icons/achievement_streak7.png',
      'key': 'fire_way'
    },
    {
      'title': 'Мастер задач',
      'subtitle': 'Выполните 100 задач',
      'condition': () => tasksCompleted >= 100,
      'starsReward': 200,
      'completed': false,
      'date': '--',
      'iconPath': 'assets/images/icons/achievement_100tasks.png',
      'key': 'task_master'
    },
    {
      'title': 'Новичок',
      'subtitle': 'Зарегистрируйтесь в приложении',
      'condition': () => false,
      'starsReward': 10,
      'completed': true,
      'date': '--.--.----',
      'iconPath': 'assets/images/icons/achievement_novice.png',
      'key': 'beginner'
    },
    {
      'title': 'Стойкий',
      'subtitle': 'Достигните 30 дней серии',
      'condition': () => currentStreak >= 30,
      'starsReward': 300,
      'completed': false,
      'date': '--',
      'iconPath': 'assets/images/icons/achievement_persistent.png',
      'key': 'strong'
    },
    {
      'title': 'Эксперт',
      'subtitle': 'Выполните 500 задач',
      'condition': () => tasksCompleted >= 500,
      'starsReward': 500,
      'completed': false,
      'date': '--',
      'iconPath': 'assets/images/icons/achievement_expert.png',
      'key': 'expert'
    },
    {
      'title': 'Легенда',
      'subtitle': 'Откройте все награды',
      'condition': (List<Map<String, dynamic>> ach) =>
          ach.where((a) => a['key'] != 'legend').every((a) => a['completed'] == true),
      'starsReward': 1000,
      'completed': false,
      'date': '--',
      'iconPath': 'assets/images/icons/achievement_legend.png',
      'key': 'legend'
    },
  ];

  // Вспомогательный метод для красивого форматирования дат
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Future<void> loadUserData() async {
    final user = await DatabaseHelper.instance.getCurrentUser();
    if (user == null) return;

    final userId = user['id'] as int;

    // Достаем и форматируем дату регистрации
    final regRaw = user['registration_date'] as String? ?? '';
    String formattedRegDate = '--.--.----';
    if (regRaw.isNotEmpty) {
      final dateTime = DateTime.tryParse(regRaw);
      if (dateTime != null) {
        formattedRegDate = _formatDate(dateTime);
      }
    }

    // загружаем статистику из БД
    tasksCompleted = await DatabaseHelper.instance.getCompletedTasksCount();
    currentStreak = await DatabaseHelper.instance.getCurrentStreak();
    streakRecord = await DatabaseHelper.instance.getStreakRecord();

    // проверяем достижения (они будут использовать актуальные цифры)
    if (!_achievementsChecked) {
      await checkAchievements(userId, formattedRegDate);
      _achievementsChecked = true;
    }

    // Загружаем баланс звезд ПОСЛЕ проверки (вдруг нам только что начислили бонус)
    final currentStarsFromDb = await DatabaseHelper.instance.getUserStars();

    // Загружаем настройки магазина
    final settings = AppSettings();
    await settings.loadSettings();

    // Расчет XP и уровней
    final unlockedAchievementsCount = achievements.where((a) => a['completed']).length;
    final calculatedXP = (tasksCompleted * 25) + (unlockedAchievementsCount * 100);
    final calculatedLevel = (calculatedXP ~/ 500) + 1;
    final xpOfCurrentLevel = (calculatedLevel - 1) * 500;
    final xpNeededForNext = calculatedLevel * 500;

    // Обновляем состояние
    userName = user['name'] as String;
    userStars = currentStarsFromDb;
    currentAvatar = settings.currentAvatar;
    currentTrophy = settings.currentTrophy;
    userLevel = calculatedLevel;
    totalXP = calculatedXP;
    xpForNextLevel = xpNeededForNext;
    currentLevelXP = calculatedXP - xpOfCurrentLevel;

    progressFraction = (xpNeededForNext - xpOfCurrentLevel) > 0
        ? currentLevelXP / (xpNeededForNext - xpOfCurrentLevel)
        : 0.0;

    // Уведомляем UI о необходимости перерисовки
    notifyListeners();
  }

  Future<void> checkAchievements(int userId, String formattedRegDate) async {
    bool changed = false;

    // Сначала ставим "Новичка"
    final noviceIndex = achievements.indexWhere((a) => a['key'] == 'beginner');
    if (noviceIndex != -1) {
      achievements[noviceIndex]['date'] = formattedRegDate;
      achievements[noviceIndex]['completed'] = true;
      changed = true;
    }

    // Проходим по остальным достижениям
    for (var i = 0; i < achievements.length; i++) {
      final ach = achievements[i];
      final key = ach['key'] as String;

      if (key == 'beginner') continue;

      // Проверяем, было ли оно уже открыто ранее (смотрим в БД)
      final unlockDateStr = await DatabaseHelper.instance.getAchievementUnlockDate(userId, key);
      if (unlockDateStr != null) {
        ach['completed'] = true;
        final parsedDate = DateTime.tryParse(unlockDateStr);
        ach['date'] = parsedDate != null ? _formatDate(parsedDate) : unlockDateStr;
        continue;
      }

      // Если в БД его еще нет, проверяем выполнил ли пользователь условие сейчас
      bool conditionMet = false;
      try {
        final condition = ach['condition'];
        if (condition is bool Function()) {
          conditionMet = condition();
        } else if (condition is bool Function(List<Map<String, dynamic>>)) {
          conditionMet = condition(achievements);
        }
      } catch (e) {
        print("Ошибка при проверке достижения $key: $e");
        continue;
      }

      // Если условие выполнено именно при этом заходе в профиль
      if (conditionMet) {
        final reward = ach['starsReward'] as int;
        final now = DateTime.now();

        // Записываем разблокировку и начисляем звезды в БД
        await DatabaseHelper.instance.unlockAchievement(
            userId: userId,
            achievementKey: key,
            starsReward: reward
        );

        // Обновляем локальный список
        ach['completed'] = true;
        ach['date'] = _formatDate(now);
        changed = true;

        // Отправляем сигнал в UI для показа уведомления
        if (onAchievementUnlocked != null) {
          onAchievementUnlocked!(ach['title'] as String, reward);
        }
      }
    }

    // Если были изменения, обновляем UI
    if (changed) {
      notifyListeners();
    }
  }
}