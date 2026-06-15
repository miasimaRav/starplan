import 'package:StarPlan/core/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:StarPlan/presentation/pages/profile_info.dart';
import '../../logic/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Инициализируем контроллер
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController();

    // Слушаем события от контроллера (для показа всплывающих уведомлений)
    _controller.onAchievementUnlocked = (title, reward) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏆 Достижение получено: $title! +$reward ★'),
            backgroundColor: Colors.amber.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    };

    // Запускаем загрузку данных
    _controller.loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose(); // Обязательно освобождаем память
    super.dispose();
  }

  void onIconPressed() {
    // переход на нужную страницу
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    ).then((_) => _controller.loadUserData()); // Обновить после редактирования
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).backgroundGradient,
        ),
        child: SafeArea(
          // ListenableBuilder автоматически перерисовывает UI, когда в контроллере вызывается notifyListeners()
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              return ProfileContent(
                controller: _controller,
                onIconPressed: onIconPressed,
              );
            },
          ),
        ),
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  final ProfileController controller;
  final VoidCallback onIconPressed;

  const ProfileContent({
    super.key,
    required this.controller,
    required this.onIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Теперь мы берем все данные напрямую из контроллера, код стал чище!
    return Column(
      children: [
        buildTopBar(context),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                buildHeaderCard(
                  context,
                  controller.userName,
                  controller.userLevel,
                  controller.totalXP,
                  controller.currentAvatar,
                  controller.currentTrophy,
                  controller.xpForNextLevel,
                  controller.progressFraction,
                ),
                const SizedBox(height: 16),
                buildStatsGrid(
                  context,
                  controller.tasksCompleted,
                  controller.currentStreak,
                  controller.streakRecord,
                  controller.totalXP,
                ),
                const SizedBox(height: 16),
                buildAchievementsSection(context, controller.achievements),
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
                overflow: TextOverflow.ellipsis,
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
                      image: currentAvatar != 'default'
                          ? DecorationImage(
                        image: AssetImage('assets/images/icons/avatar_$currentAvatar.jpg'),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    alignment: Alignment.center,
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
                duration: const Duration(microseconds: 250),
                child: IconButton(
                  icon: const Icon(Icons.edit),
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
              FractionallySizedBox(
                widthFactor: progressFraction.clamp(0.0, 1.0),
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
    super.key,
    required this.title,
    required this.value,
    required this.background,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

  const AchievementCard({
    super.key,
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
              : theme.colorScheme.primary.withOpacity(0.6),
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
                    color: onSurface,
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
              color: theme.colorScheme.primary,
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
  static LinearGradient getHeaderGradient(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.scaffoldBackgroundColor == const Color(0xFF0B0014)) {
      return const LinearGradient(
        colors: [Color(0xFF140029), Color(0xFF26004D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (theme.brightness == Brightness.light) {
      return const LinearGradient(
        colors: [Color(0xFFE0E6FF), Color(0xFFB3C5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF2343C4), Color(0xFF4C6BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static Color getStatColor(BuildContext context, String type) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final isOled = theme.scaffoldBackgroundColor == const Color(0xFF0B0014);

    switch (type) {
      case 'tasks':
        if (isLight) return const Color(0xFFE2F7EE);
        if (isOled) return const Color(0xFF063B26);
        return const Color(0xFF0C8A5F);
      case 'streak':
        if (isLight) return const Color(0xFFFFEBE8);
        if (isOled) return const Color(0xFF4D140B);
        return const Color(0xFFB33A25);
      case 'record':
        if (isLight) return const Color(0xFFF3E5FF);
        if (isOled) return const Color(0xFF350B61);
        return const Color(0xFF7A23D8);
      case 'xp':
        if (isLight) return const Color(0xFFE8E5FF);
        if (isOled) return const Color(0xFF190E61);
        return const Color(0xFF4230A6);
      default:
        return theme.cardColor;
    }
  }

  static Color getTextColor(BuildContext context, {bool isHeader = false}) {
    if (isHeader && Theme.of(context).brightness == Brightness.light) {
      return const Color(0xFF020B3B);
    }
    return Theme.of(context).colorScheme.onSurface;
  }
}