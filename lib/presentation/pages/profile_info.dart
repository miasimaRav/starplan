import 'package:StarPlan/core/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:StarPlan/presentation/pages/profile_page.dart';
import '../../logic/edit_profile_controller.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final EditProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController();

    // Подписываемся на ошибку валидации от контроллера
    _controller.onError = (message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    };

    // Подписываемся на успешное сохранение
    _controller.onSuccess = () {
      if (!mounted) return;
      Navigator.pop(context); // Возвращаемся на предыдущий экран
    };

    // Запускаем асинхронную загрузку
    _controller.loadUser();
  }

  @override
  void dispose() {
    _controller.dispose(); // Контроллер сам удалит все свои текстовые поля
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).backgroundGradient,
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              // Пока данные грузятся, показываем индикатор, чтобы избежать пустых полей
              if (_controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _ProfileContent(controller: _controller);
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final EditProfileController controller;

  const _ProfileContent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context, controller.saveProfile),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildHeaderCard(context, controller),
                const SizedBox(height: 16),
                _buildFormFields(context, controller),
                const SizedBox(height: 24),
                _buildSaveButton(context, controller.saveProfile),
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
    final onSurface = theme.colorScheme.onSurface;
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

  // Карточка с аватаром и уровнем
  Widget _buildHeaderCard(BuildContext context, EditProfileController controller) {
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
                  image: controller.currentAvatar != 'default'
                      ? DecorationImage(
                    image: AssetImage('assets/images/icons/avatar_${controller.currentAvatar}.jpg'),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                alignment: Alignment.center,
                child: controller.currentAvatar == 'default'
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
          // Слушатель поля имени для мгновенного обновления текста заголовка
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.nameController,
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
  Widget _buildFormFields(BuildContext context, EditProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(context, controller: controller.nameController, label: 'Имя', maxLength: 20),
        const SizedBox(height: 15),
        _buildTextField(context, controller: controller.registerDateController,
            label: 'Дата регистрации', hint: 'дд.мм.гггг', enabled: false),
        const SizedBox(height: 15),
        _buildTextField(context, controller: controller.birthdayController,
            label: 'Дата рождения', hint: 'дд.мм.гггг'),
        const SizedBox(height: 15),
        _buildTextField(context, controller: controller.emailController,
            label: 'Email', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 15),
        _buildTextField(context, controller: controller.levelController,
            label: 'Уровень', keyboardType: TextInputType.number, enabled: false),
        const SizedBox(height: 15),
        _buildTextField(context, controller: controller.starsController,
            label: 'Звёзды (XP)', keyboardType: TextInputType.number, enabled: false),
      ],
    );
  }

  // Адаптивный виджет поля ввода
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