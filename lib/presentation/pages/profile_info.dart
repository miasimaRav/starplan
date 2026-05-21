import 'package:flutter/material.dart';
import 'package:starplan/presentation/pages/profile_page.dart';

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

    final id = _userRow!['id'] as int;
    final name = _nameController.text.trim();
    final birthdayStr = _birthdayController.text.trim();
    final email = _emailController.text.trim();
    final level = int.tryParse(_levelController.text.trim()) ?? 1;

    await DatabaseHelper.instance.updateUser(
      id: id,
      name: name,
      birthDate: birthdayStr.isEmpty ? null : birthdayStr,
      email: email.isEmpty ? null : email,
      level: level,
    );

    if (!mounted) return;
    Navigator.pop(context); // Возвращаемся без вызова loadUserData
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
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
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
  // TextEditingController хранит текущее значение поля и позволяет:
  // задать стартовый текст
  // прочитать, что пользователь ввёл
  // программно менять текст (например, после загрузки из БД).
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
                _buildHeaderCard(context),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: theme.textTheme.titleLarge?.color),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Редактирование профиля',
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
          // правый невидимый отступ для идеального центрирования текста
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Карточка с аватаром и уровнем (только отображение)
  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    // Используем палитру для получения правильного цвета текста и градиента
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
                    image: AssetImage('assets/images/icons/avatar_$currentAvatar.png'),
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
          Text(
            'Герой StarPlan',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
        // Передаем context в каждое текстовое поле
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
            label: 'Уровень', keyboardType: TextInputType.number),
        const SizedBox(height: 15),
        _buildTextField(context, controller: starsController,
            label: 'Звёзды (XP)', keyboardType: TextInputType.number, enabled: false),
      ],
    );

  }
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
    final isLight = theme.brightness == Brightness.light;

    // Определяем базовый цвет для текста и рамок (белый для темных тем, графитовый для светлой)
    final baseColor = isLight ? const Color(0xFF1E272E) : Colors.white;

    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: TextStyle(color: baseColor),
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: baseColor),
        hintStyle: TextStyle(color: baseColor.withOpacity(0.7)),
        counterText: '',
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: baseColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          // Акцентная рамка: золотая в Дефолте, бирюзовая в OLED
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        // Для светлой темы делаем легкую тень, для темной белую дымку
        fillColor: isLight
            ? Colors.black.withOpacity(0.05)
            : Colors.white.withOpacity(0.08),
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
          // Фон кнопки подстраивается под главную тему (Золото / Неон)
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.black,
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
