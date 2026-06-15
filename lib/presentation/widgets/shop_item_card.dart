import 'package:flutter/material.dart';
import '../../core/app_settings.dart';

class ShopItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool purchased;
  final bool isActiveItem;
  final ThemeDataConfig config;
  final VoidCallback onBuy;
  final VoidCallback onApply;

  const ShopItemCard({
    super.key,
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
              // Используем белый полупрозрачный для темной темы, чтобы не сливалось с графитовыми карточками
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