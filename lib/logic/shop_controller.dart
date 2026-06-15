import 'package:flutter/material.dart';
import '../../core/app_settings.dart';
import '../../data/database.dart';
import '../../logic/ThemeProvider.dart';

/// Контроллер для магазина. Отвечает за загрузку товаров, баланс,
/// покупку и применение тем/аватаров.
class ShopController extends ChangeNotifier {
  final ThemeProvider themeProvider;
  final AppSettings settings = AppSettings();

  List<Map<String, dynamic>> _shopItems = [];
  int _currentBalance = 0;
  int _selectedCategory = 2; // 0: Темы, 1: Аватары, 2: Награды
  bool _isLoading = true;

  // Геттеры для UI
  int get currentBalance => _currentBalance;
  int get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  // Вычисляемое свойство для отфильтрованного списка
  List<Map<String, dynamic>> get filteredItems {
    return _shopItems.where((item) {
      if (_selectedCategory == 0) return item['type'] == 'theme';
      if (_selectedCategory == 1) return item['type'] == 'avatar';
      return item['type'] == 'trophy';
    }).toList();
  }

  // Колбэки для UI (для отображения снекбаров)
  void Function(String message, bool isError)? onMessage;

  ShopController({required this.themeProvider}) {
    _init();
  }

  Future<void> _init() async {
    await settings.loadSettings();
    await loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final stars = await DatabaseHelper.instance.getUserStars();
    final items = await DatabaseHelper.instance.getShopItems();

    _currentBalance = stars;
    _shopItems = items;
    _isLoading = false;
    notifyListeners();
  }

  void setCategory(int index) {
    _selectedCategory = index;
    notifyListeners();
  }

  Future<void> buyItem(Map<String, dynamic> item) async {
    final itemId = item['id'] as int;
    final cost = item['cost'] as int;

    final success = await DatabaseHelper.instance.purchaseUpgrade(itemId, cost);

    if (success) {
      await loadData(); // Перезагружаем данные (обновится баланс и статус покупки)
      onMessage?.call('Куплено: ${item['name']} (-$cost ★)', false);
    } else {
      onMessage?.call('Недостаточно звёзд или уже куплено', true);
    }
  }

  Future<void> applyItem(Map<String, dynamic> item) async {
    final type = item['type'] as String;
    final key = item['key'] as String;

    if (type == 'theme') {
      await themeProvider.changeTheme(key);
      await settings.loadSettings();
    } else if (type == 'avatar') {
      await settings.setAvatar(key);
    } else if (type == 'trophy') {
      await settings.setTrophy(key);
    }

    notifyListeners(); // Обновляем UI, так как статус "Активна" мог измениться
    onMessage?.call('Успешно применено!', false);
  }
}