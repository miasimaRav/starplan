import 'package:flutter/material.dart';
import '../../core/app_settings.dart';
import '../../logic/ThemeProvider.dart';
import '../../logic/shop_controller.dart';
import '../widgets/shop_item_card.dart';

class ShopPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const ShopPage({super.key, required this.themeProvider});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late final ShopController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShopController(themeProvider: widget.themeProvider);

    // Слушатель для показа уведомлений (SnackBars)
    _controller.onMessage = (message, isError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final themeConfig = AppSettings.themeConfigs[_controller.settings.currentTheme]
            ?? AppSettings.themeConfigs['default']!;

        return Scaffold(
          body: Container(
            decoration: themeConfig.backgroundImagePath != null
                ? BoxDecoration(image: DecorationImage(image: AssetImage(themeConfig.backgroundImagePath!), fit: BoxFit.cover))
                : BoxDecoration(gradient: Theme.of(context).backgroundGradient),
            child: SafeArea(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(themeConfig),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ThemeDataConfig config) {
    return Column(
      children: [
        _buildTopBar(config),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildBalanceCard(config),
                const SizedBox(height: 16),
                _buildCategoryTabs(config),
                const SizedBox(height: 16),
                _buildShopItemsList(config),
                const SizedBox(height: 16),
                _buildHintCard(config),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(ThemeDataConfig config) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Text('Магазин', style: TextStyle(color: config.textColor, fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeDataConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: config.shopBalanceGradient),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.2)), alignment: Alignment.center, child: Image.asset('assets/images/icons/coin.png', width: 28, height: 28)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ваш баланс', style: TextStyle(color: config.textColor.withOpacity(0.7), fontSize: 13)),
              Text('${_controller.currentBalance}', style: TextStyle(color: config.textColor, fontSize: 26, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: config.isLight ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == _controller.selectedCategory;
          return Expanded(
            child: GestureDetector(
              onTap: () => _controller.setCategory(index),
              child: Container(
                height: 36,
                decoration: BoxDecoration(color: selected ? config.primary : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                alignment: Alignment.center,
                child: Text(tabs[index], style: TextStyle(color: selected ? Colors.black : config.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShopItemsList(ThemeDataConfig config) {
    final items = _controller.filteredItems;
    if (items.isEmpty) return const Center(child: Text('Пусто'));

    return Column(
      children: items.map((item) {
        final purchased = (item['purchased'] as int?) == 1;
        // Проверка активности
        final type = item['type'];
        final key = item['key'];
        bool isActive = false;
        if (type == 'theme') isActive = _controller.settings.currentTheme == key;
        if (type == 'avatar') isActive = _controller.settings.currentAvatar == key;
        if (type == 'trophy') isActive = _controller.settings.currentTrophy == key;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShopItemCard(
            item: item,
            purchased: purchased,
            isActiveItem: isActive,
            config: config,
            onBuy: () => _controller.buyItem(item),
            onApply: () => _controller.applyItem(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHintCard(ThemeDataConfig config) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: config.isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.09), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.info, color: config.primary.withOpacity(0.9), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Зарабатывайте звёзды, выполняя задачи!', style: TextStyle(color: config.textColor.withOpacity(0.7), fontSize: 12))),
        ],
      ),
    );
  }
}
