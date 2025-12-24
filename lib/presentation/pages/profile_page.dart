import 'package:flutter/material.dart';
import 'package:starplan/presentation/pages/profile_info.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool isEditProfile = true;

  void onIconPressed() {
   /* setState(() {
      isEditProfile = !isEditProfile;
    });

    */
    // переход на нужную страницу
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: ProfileContent(
            //isEditProfile: isEditProfile,
            onIconPressed: onIconPressed,),
        ),
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  //final bool isEditProfile;
  final VoidCallback onIconPressed;

  const ProfileContent({
   // required this.isEditProfile,
    required this.onIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTopBar(),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                buildHeaderCard(),
                const SizedBox(height: 16),
                buildStatsGrid(),
                const SizedBox(height: 16),
                buildAchievementsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Верхняя панель с меню и плюсом
  Widget buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // TODO: открыть боковое меню
            },
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Профиль',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(onPressed: () {
            // TODO: Кнопку возможно заменить на иконку или придумать функционал
          },
              icon: Icon(Icons.add))
        ],
      ),
    );
  }

  // Большая карточка с уровнем, именем и прогрессом XP
  Widget buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2343C4), Color(0xFF4C6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                        color: const Color(0xFFFFC94B),
                        width: 3,
                      ),
                      color: Colors.indigo.shade900,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'SP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                    const Text(
                      'Герой StarPlan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        buildLevelChip('Уровень 12'),
                        const SizedBox(width: 6),
                        buildLevelChip('14250 XP'),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Duration(microseconds: 250),
                child: IconButton(
                  //key: ValueKey<bool>(isEditProfile),
                  icon: Icon(Icons.edit),
                  color: Colors.white,
                  onPressed: onIconPressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'До уровня 13',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
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
                widthFactor: 2450 / 3000,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC94B), Color(0xFFFF7A3C)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '2450 / 3000 XP',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildLevelChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Четыре плитки: задачи, текущая серия, рекорд, всего опыта
  static Widget buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              StatCard(
                title: 'Задач\nвыполнено',
                value: '143',
                background: const Color(0xFF0C8A5F),
                iconPath: 'assets/images/icons/check_tasks.png',
              ),
              const SizedBox(height: 8),
              StatCard(
                title: 'Рекорд\nсерии',
                value: '15',
                background: const Color(0xFF7A23D8),
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
                value: '7',
                background: const Color(0xFFB33A25),
                iconPath: "",
              ),
              const SizedBox(height: 8),
              StatCard(
                title: 'Всего\nопыта',
                value: '14250',
                background: const Color(0xFF4230A6),
                iconPath: '',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Блок с достижениями
  static Widget buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Достижения',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '3 / 6',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AchievementCard(
                title: 'Первый шаг',
                subtitle: 'Выполните первую\nзадачу',
                dateText: '15 окт 2025',
                iconPath: 'assets/images/icons/achievement_first_step.png',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AchievementCard(
                title: 'Огненная полоса',
                subtitle: 'Достигните 7 дней\nподряд',
                dateText: '28 окт 2025',
                iconPath: 'assets/images/icons/achievement_streak7.png',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AchievementCard(
                title: 'Мастер задач',
                subtitle: 'Выполните 100 задач',
                dateText: '--',
                iconPath: 'assets/images/icons/achievement_100tasks.png',
                locked: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AchievementCard(
                title: 'Легенда',
                subtitle: 'Откройте все награды',
                dateText: '--',
                iconPath: '',
                locked: true,
              ),
            ),
          ],
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
                style: const TextStyle(
                  color: Colors.white,
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
              color: Colors.white.withOpacity(0.9),
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
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: locked
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.09),
        border: Border.all(
          color: locked
              ? Colors.white.withOpacity(0.15)
              : const Color(0xFFFFC94B).withOpacity(0.6),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (locked)
                Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            dateText,
            style: const TextStyle(
              color: Color(0xFFFFC94B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
