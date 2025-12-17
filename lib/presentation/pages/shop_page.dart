import 'package:flutter/material.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {

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
        child: const SafeArea(
          child: _ShopContent(),
        ),
      ),
    );
  }
}


class _ShopContent extends StatelessWidget {
  const _ShopContent();

  @override
  Widget build(BuildContext context) {
    return Column(
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
                _buildTrophiesList(),
                const SizedBox(height: 16),
                _buildHintCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Верхняя панель
  static Widget _buildTopBar() {
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
                'Магазин',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: переход на экран пополнения / настройку магазина
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Карточка "Ваш баланс"
  static Widget _buildBalanceCard() {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.2),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/icons/coin.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Ваш баланс',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '1850',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Место под небольшую иконку/доставку
          Icon(Icons.local_shipping,
              color: Colors.white.withOpacity(0.9), size: 26),
        ],
      ),
    );
  }

  // Вкладки "Темы / Аватары / Бусты / Награды"
  static Widget _buildCategoryTabs() {
    const tabs = ['Темы', 'Аватары', 'Бусты', 'Награды'];
    final selectedIndex = 3; // сейчас выбрана вкладка "Награды"

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: смена категории и загрузка других товаров из БД
              },
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFFFC94B)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontSize: 12,
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

  // Список карточек трофеев
  static Widget _buildTrophiesList() {
    final items = [
      ShopItem(
        title: 'Бронзовый трофей',
        rarityLabel: 'Обычный',
        description: 'Декоративный трофей',
        price: 250,
        color: const Color(0xFF2140D4),
        iconPath: 'assets/images/icons/trophy_bronze.png',
        rarityColor: Colors.white.withOpacity(0.18),
      ),
      ShopItem(
        title: 'Серебряный трофей',
        rarityLabel: 'Редкий',
        description: 'Престижный трофей',
        price: 600,
        color: const Color(0xFF2140D4),
        iconPath: 'assets/images/icons/trophy_silver.png',
        rarityColor: const Color(0xFF4CC6FF),
      ),
      ShopItem(
        title: 'Золотой трофей',
        rarityLabel: 'Легендарный',
        description: 'Легендарный трофей',
        price: 1200,
        color: const Color(0xFF2140D4),
        iconPath: 'assets/images/icons/trophy_gold.png',
        rarityColor: const Color(0xFFFFC94B),
      ),
    ];

    return Column(
      children: items
          .map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShopItemCard(item: item),
      ))
          .toList(),
    );
  }

  // Нижняя подсказка
  static Widget _buildHintCard() {
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
          Icon(Icons.info,
              color: const Color(0xFFFFC94B).withOpacity(0.9), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Зарабатывайте монеты, выполняя ежедневные задачи и достигая новых уровней!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Модель товара (потом можно заменить данными из БД)
class ShopItem {
  final String title;
  final String description;
  final int price;
  final String rarityLabel;
  final Color rarityColor;
  final Color color;
  final String iconPath;

  ShopItem({
    required this.title,
    required this.description,
    required this.price,
    required this.rarityLabel,
    required this.rarityColor,
    required this.color,
    required this.iconPath,
  });
}

// Карточка товара в списке
class _ShopItemCard extends StatelessWidget {
  final ShopItem item;

  const _ShopItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: item.color.withOpacity(0.92),
      ),
      child: Row(
        children: [
          // Иконка трофея
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.black.withOpacity(0.25),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              item.iconPath,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          // Текстовая часть
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.rarityColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.rarityLabel,
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
                  item.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/icons/coin.png',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
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
          // Кнопка "Купить"
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFA22C),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              // TODO: проверка баланса, покупка, запрос к БД
            },
            child: const Text(
              'Купить',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
