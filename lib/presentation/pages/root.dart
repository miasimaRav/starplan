import 'package:flutter/material.dart';
import 'package:starplan/presentation/pages/profile_info.dart';
import 'package:starplan/presentation/pages/profile_page.dart';
import 'package:starplan/presentation/pages/shop_page.dart';

import '../../logic/ThemeProvider.dart';
import 'home_page.dart';

class RootPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const RootPage({super.key, required this.themeProvider});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0;

  // 2. Убираем const со списка страниц и делаем его поздней инициализацией
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // 3. Заполняем список страниц, передавая провайдер в ShopPage
    _pages = [
      const HomePage(),
      const ProfilePage(),
      ShopPage(themeProvider: widget.themeProvider), // Передали провайдер в магазин!
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Берем динамическую тему для нижней панели

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        // ИСПОЛЬЗУЕМ ДИНАМИЧЕСКИЕ ЦВЕТА ДЛЯ ПАНЕЛИ
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Дом'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Магазин'),
        ],
      ),
    );
  }
}
