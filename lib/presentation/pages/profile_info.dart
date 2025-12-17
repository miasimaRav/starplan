import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  // сюда потом можно передать профиль из БД
  // final ProfileModel profile;
  // const EditProfilePage({super.key, required this.profile});

  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // контроллеры для полей
  final _nameController = TextEditingController();
  final _registerDateController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _emailController = TextEditingController();
  final _levelController = TextEditingController();
  final _starsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // здесь потом подставишь данные из БД
    // final p = widget.profile;
    // _nameController.text = p.name;
    // _registerDateController.text = p.registerDateString;
    // _birthdayController.text = p.birthDateString;
    // _emailController.text = p.email;
    // _levelController.text = p.level.toString();
    // _starsController.text = p.stars.toString();

    // временные демо-значения
    _nameController.text = 'Star User';
    _registerDateController.text = '10.10.2025';
    _birthdayController.text = '01.01.2005';
    _emailController.text = 'user@example.com';
    _levelController.text = '12';
    _starsController.text = '14250';
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

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    final registerDate = _registerDateController.text.trim();
    final birthday = _birthdayController.text.trim();
    final email = _emailController.text.trim();
    final level = int.tryParse(_levelController.text.trim()) ?? 0;
    final stars = int.tryParse(_starsController.text.trim()) ?? 0;

    // TODO: здесь вызвать репозиторий / сервис БД:
    // await profileRepository.updateProfile(
    //   name: name,
    //   registerDate: registerDate,
    //   birthday: birthday,
    //   email: email,
    //   level: level,
    //   stars: stars,
    // );

    // пока просто закрываем экран
    if (!mounted) return;
    Navigator.pop(context);
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
  final TextEditingController nameController;
  final TextEditingController registerDateController;
  final TextEditingController birthdayController;
  final TextEditingController emailController;
  final TextEditingController levelController;
  final TextEditingController starsController;
  final VoidCallback onSave;

  const _ProfileContent({
    super.key,
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
                _buildHeaderCard(),
                const SizedBox(height: 16),
                _buildFormFields(),
                const SizedBox(height: 24),
                _buildSaveButton(onSave),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Верхняя панель
  Widget _buildTopBar(BuildContext context, VoidCallback onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Редактирование профиля',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Карточка с аватаром и уровнем (только отображение)
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2343C4), Color(0xFF4C6BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                    color: const Color(0xFFFFC94B),
                    width: 3,
                  ),
                  color: Colors.indigo.shade900,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'SP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
          const Text(
            'Герой StarPlan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Поля формы
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: nameController,
          label: 'Имя',
          maxLength: 20,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: registerDateController,
          label: 'Дата регистрации',
          hint: 'дд.мм.гггг',
          enabled: false,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: birthdayController,
          label: 'Дата рождения',
          hint: 'дд.мм.гггг',
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: emailController,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: levelController,
          label: 'Уровень',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: starsController,
          label: 'Звёзды (XP)',
          keyboardType: TextInputType.number,
          enabled:false,
        ),
      ],
    );

  }
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int? maxLength,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        counterText: '',
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFFC94B), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
      ),
    );
  }

  Widget _buildSaveButton(VoidCallback onSave) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC94B),
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
