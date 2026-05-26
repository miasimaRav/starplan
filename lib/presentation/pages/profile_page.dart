import 'package:flutter/material.dart';
import 'package:StarPlan/presentation/pages/profile_info.dart';
import '../../core/app_settings.dart';
import '../../data/database.dart'; // Подключаем DatabaseHelper

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool isEditProfile = true;

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

  // Достижения
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

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

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
    await checkAchievements(userId, formattedRegDate);
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
    // Обновляем интерфейс
    setState(() {
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
    });
  }

  Future<void> checkAchievements(int userId, String formattedRegDate) async {
    // Сначала ставим "Новичка"
    final noviceIndex = achievements.indexWhere((a) => a['key'] == 'beginner');
    if (noviceIndex != -1) {
      achievements[noviceIndex]['date'] = formattedRegDate;
      achievements[noviceIndex]['completed'] = true;
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
        continue; // Идем к следующему
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

        // Показываем радостное уведомление пользователю
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Достижение получено: ${ach['title']}! +$reward ★'),
              backgroundColor: Colors.amber.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void onIconPressed() {
    // переход на нужную страницу
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    ).then((_) => loadUserData()); // Обновить после редактирования
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).backgroundGradient,
        ),
        child: SafeArea(
          child: ProfileContent(onIconPressed: onIconPressed),
        ),
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  final VoidCallback onIconPressed;

  const ProfileContent({
    required this.onIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Доступ к состоянию для данных
    final state = context.findAncestorStateOfType<ProfilePageState>()!;
    final userName = state.userName;
    final userLevel = state.userLevel;
    final totalXP = state.totalXP;
    final tasksCompleted = state.tasksCompleted;
    final currentStreak = state.currentStreak;
    final streakRecord = state.streakRecord;
    final achievements = state.achievements;
    final currentAvatar = state.currentAvatar;
    final currentTrophy = state.currentTrophy;
    final xpForNextLevel = state.xpForNextLevel;
    final progressFraction = state.progressFraction;

    return Column(
      children: [
        buildTopBar(context),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                buildHeaderCard(context, userName, userLevel, totalXP,
                    currentAvatar, currentTrophy, xpForNextLevel, progressFraction),
                const SizedBox(height: 16),
                buildStatsGrid(context, tasksCompleted, currentStreak, streakRecord, totalXP),
                const SizedBox(height: 16),
                buildAchievementsSection(context, achievements),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Верхняя панель с меню и плюсом
  Widget buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Профиль',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // если экран совсем узкий,
                // текст аккуратно сократится
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Большая карточка с уровнем, именем и прогрессом XP
  Widget buildHeaderCard(BuildContext context, String userName, int userLevel,
      int totalXP, String currentAvatar, String currentTrophy,
      int xpForNextLevel, double progressFraction) {
    final textColor = ProfilePalette.getTextColor(context, isHeader: true);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: ProfilePalette.getHeaderGradient(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Аватар с рамкой и короной
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      color: Colors.indigo.shade900,
                      // картинка:
                      image: currentAvatar != 'default'
                          ? DecorationImage(
                        image: AssetImage('assets/images/icons/avatar_$currentAvatar.jpg'),
                        fit: BoxFit.cover,
                      )
                          : null, // Если default, картинки нет
                    ),
                    alignment: Alignment.center,
                    // ТЕКСТ 'SP' ПОКАЗЫВАЕТСЯ ТОЛЬКО ЕСЛИ НЕТ КАРТИНКИ:
                    child: currentAvatar == 'default'
                        ? Text(
                      'SP',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Image.asset(
                        'assets/images/icons/crown.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ПОКАЗЫВАЕМ КУБОК, ЕСЛИ ОН ВЫБРАН
                        if (currentTrophy != 'none') ...[
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/images/icons/trophy_$currentTrophy.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        buildLevelChip(context, 'Уровень $userLevel'),
                        const SizedBox(width: 6),
                        buildLevelChip(context, '$totalXP XP'),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Duration(microseconds: 250),
                child: IconButton(
                  icon: Icon(Icons.edit),
                  color: textColor,
                  onPressed: onIconPressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'До уровня ${userLevel + 1}',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
              // ДИНАМИЧЕСКАЯ ПОЛОСА ПРОГРЕССА
              FractionallySizedBox(
                widthFactor: progressFraction.clamp(0.0, 1.0), // Защита от переполнения
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$totalXP / $xpForNextLevel XP',
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildLevelChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Четыре плитки: задачи, текущая серия, рекорд, всего опыта
  static Widget buildStatsGrid(BuildContext context, int tasksCompleted, int currentStreak, int streakRecord, int totalXP) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              StatCard(
                title: 'Задач\nвыполнено',
                value: '$tasksCompleted',
                background: ProfilePalette.getStatColor(context, 'tasks'),
                iconPath: 'assets/images/icons/check_tasks.png',
              ),
              const SizedBox(height: 8),
              StatCard(
                title: 'Рекорд\nсерии',
                value: '$streakRecord',
                background: ProfilePalette.getStatColor(context, 'record'),
                iconPath: 'assets/images/icons/streak_record.png',
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              StatCard(
                title: 'Текущая\nсерия',
                value: '$currentStreak',
                background: ProfilePalette.getStatColor(context, 'streak'),
                iconPath: 'assets/images/icons/streak_now.png',
              ),
              const SizedBox(height: 8),
              StatCard(
                title: 'Всего\nопыта',
                value: '$totalXP',
                background: ProfilePalette.getStatColor(context, 'xp'),
                iconPath: 'assets/images/icons/xp_icon.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Блок с достижениями
  static Widget buildAchievementsSection(BuildContext context, List<Map<String, dynamic>> achievements) {
    final theme = Theme.of(context);
    final completedCount = achievements.where((a) => a['completed']).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Достижения',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$completedCount / ${achievements.length}',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final ach = achievements[index];
            return AchievementCard(
              title: ach['title'],
              subtitle: ach['subtitle'],
              dateText: ach['date'],
              iconPath: ach['iconPath'],
              locked: !ach['completed'],
            );
          },
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color background;
  final String iconPath;

  const StatCard({
    required this.title,
    required this.value,
    required this.background,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Используем onSurface (темный для светлой темы, светлый для темной)
    final textColor = theme.colorScheme.onSurface;
    return Container(
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Image.asset(iconPath, fit: BoxFit.contain),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String dateText;
  final String iconPath;
  final bool locked;

  const AchievementCard({super.key,
    required this.title,
    required this.subtitle,
    required this.dateText,
    required this.iconPath,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: locked
            ? onSurface.withOpacity(0.05)
            : onSurface.withOpacity(0.09),
        border: Border.all(
          color: locked
              ? onSurface.withOpacity(0.15)
              : theme.colorScheme.primary.withOpacity(0.6), // Рамка цвета темы
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                height: 26,
                width: 26,
                child: Image.asset(iconPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: onSurface, // Адаптивный текст
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (locked)
                Icon(
                  Icons.lock,
                  size: 16,
                  color: onSurface.withOpacity(0.4),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: onSurface.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            dateText,
            style: TextStyle(
              color: theme.colorScheme.primary, // Дата цветом темы (а не только желтым)
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

}

class ProfilePalette {
  // Возвращает уникальный градиент для шапки в зависимости от темы
  static LinearGradient getHeaderGradient(BuildContext context) {
    final theme = Theme.of(context);

    // Если это OLED-тема (проверяем по вашему цвету фона из AppSettings)
    if (theme.scaffoldBackgroundColor == const Color(0xFF0B0014)) {
      return const LinearGradient(
        colors: [Color(0xFF140029), Color(0xFF26004D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Если это светлая тема
    if (theme.brightness == Brightness.light) {
      return const LinearGradient(
        colors: [Color(0xFFE0E6FF), Color(0xFFB3C5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    // Дефолтная сине-голубая тема «Земля»
    return const LinearGradient(
      colors: [Color(0xFF2343C4), Color(0xFF4C6BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Возвращает свой цвет для каждого типа карточки статистики
  static Color getStatColor(BuildContext context, String type) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isOled = theme.scaffoldBackgroundColor == const Color(0xFF0B0014);

    switch (type) {
      case 'tasks': // Изначально зеленый
        if (isLight) return const Color(0xFFE2F7EE);
        if (isOled) return const Color(0xFF063B26);
        return const Color(0xFF0C8A5F);
      case 'streak': // Изначально красный
        if (isLight) return const Color(0xFFFFEBE8);
        if (isOled) return const Color(0xFF4D140B);
        return const Color(0xFFB33A25);
      case 'record': // Изначально фиолетовый
        if (isLight) return const Color(0xFFF3E5FF);
        if (isOled) return const Color(0xFF350B61);
        return const Color(0xFF7A23D8);
      case 'xp': // Изначально индиго
        if (isLight) return const Color(0xFFE8E5FF);
        if (isOled) return const Color(0xFF190E61);
        return const Color(0xFF4230A6);
      default:
        return theme.cardColor;
    }
  }

  // Адаптивный цвет текста внутри цветных карточек
  static Color getTextColor(BuildContext context, {bool isHeader = false}) {
    if (isHeader && Theme.of(context).brightness == Brightness.light) {
      return const Color(0xFF020B3B); // Темный текст для светлой шапки
    }
    return Theme.of(context).colorScheme.onSurface; // Белый текст для темных и OLED фонов
  }
}