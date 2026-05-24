import 'package:flutter/material.dart';
import '../../core/app_settings.dart';
import '../../data/database.dart';
import '../../logic/ThemeProvider.dart';

/// Экран магазина (ShopPage), предоставляющий пользователю возможность
/// приобретать темы оформления, аватары и награды за заработанные звёзды.
class ShopPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ShopPage({super.key, required this.themeProvider});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AppSettings _settings = AppSettings();
  int currentBalance = 100;
  int selectedCategory = 2;

  List<Map<String, dynamic>> shopItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndData();
  }

  Future<void> _loadSettingsAndData() async {
    await _settings.loadSettings(); // Загружаем текущую активную тему
    await _loadData(); // Загружаем данные БД
  }

  Future<void> _loadData() async {
    final stars = await DatabaseHelper.instance.getUserStars();
    final items = await DatabaseHelper.instance.getShopItems();

    if (!mounted) return;

    setState(() {
      currentBalance = stars;
      shopItems = items;
      isLoading = false;
    });
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    final itemId = item['id'] as int;
    final cost = item['cost'] as int;

    final success = await DatabaseHelper.instance.purchaseUpgrade(itemId, cost);

    if (success) {
      await _loadData(); // Полностью перезагружаем данные
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Куплено: ${item['name']} (-$cost ★)'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Недостаточно звёзд или уже куплено'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = shopItems.where((item) {
      if (selectedCategory == 0) return item['type'] == 'theme';
      if (selectedCategory == 1) return item['type'] == 'avatar';
      return item['type'] == 'trophy';
    }).toList();

    // Получаем текущую конфигурацию через ваш класс AppSettings
    final themeConfig = AppSettings.themeConfigs[_settings.currentTheme]
        ?? AppSettings.themeConfigs['default']!;

    return Scaffold(
      body: Container(
        // Логика фона: картинка или градиент (убедитесь, что в AppSettings поправлен цвет проверки для космоса!)
        decoration: themeConfig.backgroundImagePath != null
            ? BoxDecoration(
          image: DecorationImage(
            image: AssetImage(themeConfig.backgroundImagePath!),
            fit: BoxFit.cover,
          ),
        )
            : BoxDecoration(
          gradient: Theme.of(context).backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(themeConfig),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildBalanceCard(themeConfig),
                      const SizedBox(height: 16),
                      _buildCategoryTabs(themeConfig),
                      const SizedBox(height: 16),
                      _buildShopItemsList(filteredItems, themeConfig),
                      const SizedBox(height: 16),
                      _buildHintCard(themeConfig),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeDataConfig config) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Магазин',
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ThemeDataConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: config.shopBalanceGradient,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.2),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/icons/coin.png',
              width: 28,
              height: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ваш баланс',
                style: TextStyle(color: config.textColor.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '$currentBalance',
                style: TextStyle(
                  color: config.textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.star, color: config.primary, size: 28),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeDataConfig config) {
    const tabs = ['Темы', 'Аватары', 'Награды'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: config.isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == selectedCategory;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = index;
                });
              },
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? config.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.black : config.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShopItemsList(List<Map<String, dynamic>> items, ThemeDataConfig config) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'В этой категории пока пусто',
            style: TextStyle(color: config.textColor.withOpacity(0.7), fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final purchased = (item['purchased'] as int?) == 1;

        final isActive = (item['type'] == 'theme' && _settings.currentTheme == item['key']) ||
            (item['type'] == 'avatar' && _settings.currentAvatar == item['key']) ||
            (item['type'] == 'trophy' && _settings.currentTrophy == item['key']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShopItemCard(
            item: item,
            purchased: purchased,
            isActiveItem: isActive,
            config: config,
            onBuy: () => _buyItem(item),
            onApply: () async {
              if (item['type'] == 'theme') {
                await widget.themeProvider.changeTheme(item['key'] ?? 'default');
                await _settings.loadSettings();
                setState(() {});
              } else if (item['type'] == 'avatar') {
                await _settings.setAvatar(item['key'] ?? 'default');
                setState(() {});
              } else if (item['type'] == 'trophy') {
                await _settings.setTrophy(item['key'] ?? 'none');
                setState(() {});
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Успешно применено!'),
                    backgroundColor: Colors.green
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHintCard(ThemeDataConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: config.primary.withOpacity(0.9), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Зарабатывайте звёзды, выполняя задачи и получая достижения!',
              style: TextStyle(color: config.textColor.withOpacity(0.7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool purchased;
  final bool isActiveItem;
  final ThemeDataConfig config;
  final VoidCallback onBuy;
  final VoidCallback onApply;

  const _ShopItemCard({
    required this.item,
    required this.purchased,
    required this.isActiveItem,
    required this.config,
    required this.onBuy,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isTheme = item['type'] == 'theme';
    final cost = item['cost'] as int;
    final rarityColor = _getRarityColor(cost);

    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: config.shopCardColor,
      ),
      child: Row(
        children: [
          // Иконка товара
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              // ИСПРАВЛЕНИЕ: Используем белый полупрозрачный для темной темы, чтобы не сливалось с графитовыми карточками
              color: config.isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.08),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                item['icon_path'] ?? 'assets/images/icons/coin.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.star,
                  color: config.primary,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Информация о товаре
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] as String,
                        style: TextStyle(
                          color: config.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: rarityColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _getRarityLabel(cost),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isTheme ? 'Оформление приложения' : (item['type'] as String),
                  style: TextStyle(color: config.textColor.withOpacity(0.7), fontSize: 11),
                ),
                const Spacer(),
                Row(
                  children: [
                    Image.asset('assets/images/icons/coin.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$cost',
                      style: TextStyle(
                        color: config.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Кнопка выбора состояния
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (isActiveItem) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: config.isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          elevation: 0,
        ),
        onPressed: null,
        child: Text('Активна', style: TextStyle(fontSize: 12, color: config.textColor.withOpacity(0.5))),
      );
    }

    if (purchased) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        onPressed: onApply,
        child: const Text('Применить', style: TextStyle(fontSize: 12, color: Colors.white)),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: config.shopButtonColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: onBuy,
      child: Text('Купить', style: TextStyle(fontSize: 12, color: config.shopButtonTextColor)),
    );
  }

  String _getRarityLabel(int cost) {
    if (cost == 0) return 'Базовый';
    if (cost <= 50) return 'Обычный';
    if (cost <= 100) return 'Редкий';
    return 'Легендарный';
  }

  Color _getRarityColor(int cost) {
    if (cost == 0) return Colors.grey.withOpacity(0.4);
    if (cost <= 50) return config.isLight ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.18);
    if (cost <= 100) return const Color(0xFF008bcc);
    return const Color(0xFFcc8f00);
  }
}