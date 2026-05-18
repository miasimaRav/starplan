import 'package:flutter/material.dart';
import '../../core/app_settings.dart';
import '../../data/database.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int currentBalance = 100;
  int selectedCategory = 2;

  List<Map<String, dynamic>> shopItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    //await DatabaseHelper.instance.initShopItems();
    final stars = await DatabaseHelper.instance.getUserStars();
    final items = await DatabaseHelper.instance.getShopItems();

    if (!mounted) return;

    setState(() {
      currentBalance = stars;
      shopItems = items;
      isLoading = false;
    });

    print("Текущий баланс из БД: $stars");
    print("Количество товаров в БД: ${items.length}");

    print("Локальный currentBalance установлен в: $currentBalance");
  }

  Future<void> _buyItem(Map<String, dynamic> item) async {
    final itemId = item['id'] as int;
    final cost = item['cost'] as int;

    final success = await DatabaseHelper.instance.purchaseUpgrade(itemId, cost);

    if (success) {
      // Полностью перезагружаем данные, чтобы видеть актуальный баланс и статус purchased
      await _loadData();

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
          duration: const Duration(seconds: 2),     //
          behavior: SnackBarBehavior.floating,      // выглядит современнее
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildBalanceCard(),
                      const SizedBox(height: 16),
                      _buildCategoryTabs(),
                      const SizedBox(height: 16),
                      _buildShopItemsList(filteredItems),
                      const SizedBox(height: 16),
                      _buildHintCard(),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Магазин',
                style: TextStyle(
                  color: Colors.white,
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

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF233DD2), Color(0xFF435CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              const Text(
                'Ваш баланс',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '$currentBalance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.star, color: Colors.amber, size: 28),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    const tabs = ['Темы', 'Аватары', 'Награды'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
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
                  color: selected ? const Color(0xFFFFC94B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
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

  Widget _buildShopItemsList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'В этой категории пока пусто',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        final purchased = (item['purchased'] as int?) == 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ShopItemCard(
            item: item,
            purchased: purchased,
            onBuy: () => _buyItem(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: const Color(0xFFFFC94B).withOpacity(0.9), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Зарабатывайте звёзды, выполняя задачи и получая достижения!',
              style: TextStyle(color: Colors.white70, fontSize: 12),
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
  final VoidCallback onBuy;

  const _ShopItemCard({
    required this.item,
    required this.purchased,
    required this.onBuy,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final isTheme = item['type'] == 'theme';
    final isAvatar = item['type'] == 'avatar';
    final rarityColor = _getRarityColor(item['cost'] as int);

    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF2140D4).withOpacity(0.92),
      ),
      child: Row(
        children: [
          // Иконка товара
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.25),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                item['icon_path'] ?? 'assets/images/icons/coin.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.star,
                  color: Colors.amber,
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
                        style: const TextStyle(
                          color: Colors.white,
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
                        _getRarityLabel(item['cost'] as int),
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
                  item['type'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Spacer(),
                Row(
                  children: [
                    Image.asset('assets/images/icons/coin.png', width: 16, height: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${item['cost']}',
                      style: const TextStyle(
                        color: Colors.white,
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

          // Кнопка
          if (purchased)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: () async {
                final settings = await AppSettings(); // создаём экземпляр
                await settings.loadSettings();

                if (isTheme) {
                  await settings.setTheme(item['key'] ?? item['name']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Тема применена'), backgroundColor: Colors.green),
                  );
                } else if (isAvatar) {
                  await settings.setAvatar(item['key'] ?? item['name']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Аватар установлен'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Применить', style: TextStyle(fontSize: 12)),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA22C),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              onPressed: onBuy,
              child: const Text('Купить', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  String _getRarityLabel(int cost) {
    if (cost <= 300) return 'Обычный';
    if (cost <= 700) return 'Редкий';
    return 'Легендарный';
  }

  Color _getRarityColor(int cost) {
    if (cost <= 300) return Colors.white.withOpacity(0.18);
    if (cost <= 700) return const Color(0xFF4CC6FF);
    return const Color(0xFFFFC94B);
  }
}