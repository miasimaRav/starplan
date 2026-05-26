import 'package:flutter/material.dart';
import 'package:StarPlan/presentation/pages/profile_page.dart';

import '../../core/app_settings.dart';
import '../../data/database.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String currentAvatar = 'default';
  Map<String, dynamic>? _userRow;

  final _nameController = TextEditingController();
  final _registerDateController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _levelController = TextEditingController();
  final _starsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final row = await DatabaseHelper.instance.getCurrentUser();
    if (row == null) return;

    final reg = row['registration_date'] as String;
    final regDate = DateTime.tryParse(reg);

    // Загружаем аватар
    final settings = AppSettings();
    await settings.loadSettings();
    setState(() {
      _userRow = row;
      currentAvatar = settings.currentAvatar;
      _nameController.text = row['name'] as String? ?? 'User';
      _registerDateController.text = regDate != null
          ? '${regDate.day.toString().padLeft(2, '0')}.${regDate.month.toString().padLeft(2, '0')}.${regDate.year}'
          : '';
      _birthdayController.text = row['birth_date'] as String? ?? '';
      _emailController.text = row['email'] as String? ?? '';
      _levelController.text = (row['level'] ?? 1).toString();
      _starsController.text = (row['stars'] ?? 100).toString();
    });
  }

  Future<void> _onSave() async {
    if (_userRow == null) {
      Navigator.pop(context);
      return;
    }

    final emailStr = _emailController.text.trim();
    final birthdayStr = _birthdayController.text.trim();

    // 1. ПРОВЕРКА EMAIL (если поле не пустое)
    if (emailStr.isNotEmpty) {
      // Паттерн: строка@строка.строка (от 2 до 4 символов в домене)
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(emailStr)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, введите корректный email (например, user@mail.com)',
              style: TextStyle(
              fontSize: 14,
                color: Colors.white,
            ),),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Прерываем сохранение
      }
    }

    // 2. ПРОВЕРКА ДАТЫ РОЖДЕНИЯ (если поле не пустое)
    if (birthdayStr.isNotEmpty) {
      // Паттерн: строгий формат ДД.ММ.ГГГГ с проверкой адекватности чисел (01-31.01-12.XXXX)
      final dateRegex = RegExp(r'^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.\d{4}$');
      if (!dateRegex.hasMatch(birthdayStr)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, введите дату в формате ДД.ММ.ГГГГ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Прерываем сохранение
      }
    }

    final id = _userRow!['id'] as int;
    final name = _nameController.text.trim();
    final level = int.tryParse(_levelController.text.trim()) ?? 1;

    await DatabaseHelper.instance.updateUser(
      id: id,
      name: name,
      birthDate: birthdayStr.isEmpty ? null : birthdayStr,
      email: emailStr.isEmpty ? null : emailStr,
      level: level,
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _registerDateController.dispose();
    _birthdayController.dispose();
    _emailController.dispose();
    _levelController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // ИСПОЛЬЗУЕМ НАШ УМНЫЙ ГРАДИЕНТ ВМЕСТО КАРТИНКИ
          gradient: Theme.of(context).backgroundGradient,
        ),
        child: SafeArea(
          child: _ProfileContent(
            currentAvatar: currentAvatar,
            nameController: _nameController,
            registerDateController: _registerDateController,
            birthdayController: _birthdayController,
            emailController: _emailController,
            levelController: _levelController,
            starsController: _starsController,
            onSave: _onSave,
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final String currentAvatar;
  final TextEditingController nameController;
  final TextEditingController registerDateController;
  final TextEditingController birthdayController;
  final TextEditingController emailController;
  final TextEditingController levelController;
  final TextEditingController starsController;
  final VoidCallback onSave;

  const _ProfileContent({
    super.key,
    required this.currentAvatar,
    required this.nameController,
    required this.registerDateController,
    required this.birthdayController,
    required this.emailController,
    required this.levelController,
    required this.starsController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context, onSave),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Передаем nameController для отображения имени
                _buildHeaderCard(context, nameController),
                const SizedBox(height: 16),
                _buildFormFields(context),
                const SizedBox(height: 24),
                _buildSaveButton(context, onSave),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Верхняя панель
  Widget _buildTopBar(BuildContext context, VoidCallback onSave) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface; // Адаптивный цвет
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: onSurface),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Редактирование профиля',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Карточка с аватаром и уровнем (теперь с реальным именем)
  Widget _buildHeaderCard(BuildContext context, TextEditingController nameCtrl) {
    final theme = Theme.of(context);
    final textColor = ProfilePalette.getTextColor(context, isHeader: true);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: ProfilePalette.getHeaderGradient(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
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
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
                )
                    : null,
              ),
              SizedBox(
                width: 35,
                height: 35,
                child: Image.asset(
                  'assets/images/icons/crown.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Обернули текст в ValueListenableBuilder, чтобы он менялся синхронно с полем ввода!
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: nameCtrl,
            builder: (context, value, child) {
              return Text(
                value.text.isNotEmpty ? value.text : 'Безымянный Герой',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ],
      ),
    );
  }

  // Поля формы
  Widget _buildFormFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(context, controller: nameController, label: 'Имя', maxLength: 20),
        const SizedBox(height: 15),
        _buildTextField(context, controller: registerDateController,
            label: 'Дата регистрации', hint: 'дд.мм.гггг', enabled: false),
        const SizedBox(height: 15),
        _buildTextField(context, controller: birthdayController,
            label: 'Дата рождения', hint: 'дд.мм.гггг'),
        const SizedBox(height: 15),
        _buildTextField(context, controller: emailController,
            label: 'Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _buildTextField(context, controller: levelController,
            label: 'Уровень', keyboardType: TextInputType.number, enabled: false),
        const SizedBox(height: 15),
        _buildTextField(context, controller: starsController,
            label: 'Звёзды (XP)', keyboardType: TextInputType.number, enabled: false),
      ],
    );
  }

  // Обновленный адаптивный виджет поля ввода
  Widget _buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        String? hint,
        int? maxLength,
        TextInputType? keyboardType,
        bool enabled = true,
      }) {
    final theme = Theme.of(context);
    // Теперь цвет жестко привязан к системе: темный для светлой темы, белый для темной
    final onSurface = theme.colorScheme.onSurface;

    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: TextStyle(color: onSurface),
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: onSurface.withOpacity(0.8)),
        hintStyle: TextStyle(color: onSurface.withOpacity(0.5)),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: onSurface.withOpacity(0.3), width: 1),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: onSurface.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: onSurface.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, VoidCallback onSave) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.black, // Текст на кнопке всегда черный для контраста
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Сохранить',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}