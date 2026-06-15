import 'package:flutter/material.dart';
import 'package:StarPlan/core/app_settings.dart';
import 'package:StarPlan/core/constants/app_colors.dart';

import '../../data/models/day_status.dart';
import '../../data/models/task_model.dart';
import '../../logic/home_controller.dart';
import '../widgets/empty_tasks_widget.dart';
import '../widgets/task_row_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

enum ViewMode { month, week, day }

class HomePageState extends State<HomePage> {
  ViewMode viewMode = ViewMode.month;
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime selectedDate = DateTime.now();
  ThemeData get theme => Theme.of(context);

  final HomeController controller = HomeController();

  List<Task> _dayTasks = [];
  final Map<DateTime, DayStatus> days = {};

  int completedDaysInMonth = 0;
  int activeDaysInMonth = 0;

  List<String> monthNames = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];

  String get currentMonthName => monthNames[currentMonth.month];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      loadTasks(selectedDate),
      loadDayStats(selectedDate),
      loadMonthStats(currentMonth),
    ]);
  }

  Future<void> loadTasks(DateTime date) async {
    final tasks = await controller.loadTasks(date);
    if (!mounted) return;
    setState(() => _dayTasks = tasks);
  }

  Future<void> loadDayStats(DateTime date) async {
    final stats = await controller.loadDayStats(date);
    if (!mounted) return;

    final normalizedDate = DateTime(date.year, date.month, date.day);

    setState(() {
      if (stats['total'] == 0) {
        days.remove(normalizedDate);
      } else {
        final done = stats['done'] ?? 0;
        final total = stats['total'] ?? 0;

        DayType type = DayType.warning;
        if (done == total && total > 0) type = DayType.completed;
        else if (done == 0) type = DayType.failed;

        days[normalizedDate] = DayStatus(
          doneTasks: done,
          totalTasks: total,
          type: type,
        );
      }

      //пересчитываем карточку, если изменилось состояние конкретного дня
      _updateMotivationStats();
    });
  }

  Future<void> loadMonthStats(DateTime month) async {
    final statsMap = await controller.loadMonthStats(month);

    final Map<DateTime, DayStatus> newDays = {};

    statsMap.forEach((date, status) {
      newDays[date] = status;
    });

    if (!mounted) return;

    setState(() {
      days
        ..clear()
        ..addAll(newDays);

      // автоматически пересчитываем карточку при загрузке месяца
      _updateMotivationStats();
    });
  }

// Обновление всех данных текущего представления и мотивационной карточки
  Future<void> _refreshCurrentView() async {
    if (!mounted) return;

    // Сначала загружаем общую карту месяца
    await loadMonthStats(currentMonth);

    // Точечно обновляем задачи и показатели выбранного дня
    await Future.wait([
      loadTasks(selectedDate),    // обновляет список _dayTasks
      loadDayStats(selectedDate), // накладывает точную статистику на выбранный день
    ]);

  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Получаем текущую тему

    return Scaffold(
      body: Container(
        // Используем нашу новую функцию для получения нужного градиента
        decoration: BoxDecoration(
          gradient: Theme.of(context).backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              buildTopBar(),
              const SizedBox(height: 8),
              buildPeriodSwitch(),
              const SizedBox(height: 8),
              buildMainContent(),
              const SizedBox(height: 8),
              buildMotivationCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMainContent() {
    switch (viewMode) {
      case ViewMode.month:
        return buildCalendar();        // текущий месячный календарь
      case ViewMode.week:
        return buildWeekView();        // неделя
      case ViewMode.day:
        return buildDayView();         // детальный день
    }
  }

  Future<void> addTasksBottomSheet({Task? taskToEdit}) async {
    final isEditing = taskToEdit != null;
    String? titleError;

    DateTime? startDate = isEditing ? taskToEdit.startDate : selectedDate;
    DateTime? endDate = isEditing ? taskToEdit.endDate : selectedDate;
    int selectedDifficulty = isEditing ? taskToEdit.difficulty : 1;

    int calculatedStars = isEditing ? taskToEdit.stars : (selectedDifficulty * 1);

    final titleController = TextEditingController(text: isEditing ? taskToEdit.title : '');
    // Если описание null, ставим пустую строку
    final descriptionController = TextEditingController(text: isEditing ? (taskToEdit.description ?? '') : '');

    void updateStars(StateSetter setSheetState) {
      DateTime taskStart = startDate ?? selectedDate;
      DateTime taskEnd = endDate ?? taskStart;
      if (taskEnd.isBefore(taskStart)) {
        final tmp = taskStart;
        taskStart = taskEnd;
        taskEnd = tmp;
      }
      final days = taskEnd.difference(taskStart).inDays + 1;
      final newStars = selectedDifficulty * days;
      setSheetState(() {
        calculatedStars = newStars;
      });
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.50,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Шапка
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        isEditing ? 'Редактирование' : 'Новое задание',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final title = titleController.text.trim();

                          if (title.isEmpty) {
                            setSheetState(() {
                              titleError = 'Обязательное поле';
                            });
                            return;
                          }
                          setSheetState(() {
                            titleError = null;
                          });

                          // Это заставит базу перезаписать старое описание на пустое
                          final description = descriptionController.text.trim();

                          DateTime taskStart = startDate ?? selectedDate;
                          DateTime taskEnd = endDate ?? taskStart;
                          if (taskEnd.isBefore(taskStart)) {
                            final tmp = taskStart;
                            taskStart = taskEnd;
                            taskEnd = tmp;
                          }
                          final days = taskEnd.difference(taskStart).inDays + 1;
                          final stars = selectedDifficulty * days;

                          if (isEditing) {
                            await controller.updateTask(
                              id: taskToEdit.id!,
                              title: title,
                              description: description,
                              difficulty: selectedDifficulty,
                              startDate: taskStart,
                              endDate: taskEnd,
                              stars: stars,
                            );
                          } else {
                            await controller.createTask(
                              title: title,
                              description: description,
                              difficulty: selectedDifficulty,
                              startDate: taskStart,
                              endDate: taskEnd,
                              stars: stars,
                            );
                          }

                          await Future.wait([
                            loadTasks(selectedDate),
                            loadDayStats(selectedDate),
                            loadMonthStats(currentMonth),
                          ]);

                          if (!mounted) return;

                          // Закрываем шторку
                          Navigator.pop(context);

                          // ИСПРАВЛЕНИЕ 3: Показываем уведомление (SnackBar) для пользователя
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing ? 'Задача успешно обновлена!' : 'Новая задача создана!',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            'Сохранить',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    children: [
                      buildSectionTitle('Основная информация'),
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Название задачи',
                          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                          errorText: titleError,
                          errorStyle: const TextStyle(color: Colors.redAccent),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withOpacity(0.06),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            titleError = value.trim().isEmpty ? 'Обязательное поле' : null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Описание (необязательно)',
                          labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.onSurface.withOpacity(0.06),
                        ),
                      ),
                      const SizedBox(height: 28),
                      buildSectionTitle('Сложность'),
                      buildDifficultyDropdown(selectedDifficulty, (value) {
                        if (value != null) {
                          setSheetState(() {
                            selectedDifficulty = value;
                          });
                          updateStars(setSheetState);
                        }
                      }),
                      const SizedBox(height: 28),
                      buildSectionTitle('Сроки выполнения'),
                      buildDatePickerRow(
                        start: startDate,
                        end: endDate,
                        onPickStart: () async {
                          final picked = await pickDate(context, startDate ?? selectedDate);
                          if (picked != null) {
                            setSheetState(() {
                              startDate = picked;
                            });
                            updateStars(setSheetState);
                          }
                        },
                        onPickEnd: () async {
                          final picked = await pickDate(context, endDate ?? selectedDate);
                          if (picked != null) {
                            setSheetState(() {
                              endDate = picked;
                            });
                            updateStars(setSheetState);
                          }
                        },
                      ),
                      const SizedBox(height: 28),
                      buildSectionTitle('Ожидаемая награда'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: theme.colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              '$calculatedStars звёзд',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget buildDatePickerRow({
    required DateTime? start,
    required DateTime? end,
    required VoidCallback onPickStart,
    required VoidCallback onPickEnd,
  }) =>
      IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: buildDateButton(
                label: start == null
                    ? 'Начало'
                    : '${start.day}.${start.month}.${start.year}',
                onTap: onPickStart,
              ),
            ),
            Container(
              width: 2,
              height: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: buildDateButton(
                label: end == null
                    ? 'Конец'
                    : '${end.day}.${end.month}.${end.year}',
                onTap: onPickEnd,
              ),
            ),
          ],
        ),
      );


  Widget buildDifficultyDropdown(int value, void Function(int?) onChanged) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        dropdownColor: theme.cardColor,
        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
        items: const [
          DropdownMenuItem(value: 1, child: Text('1 - Очень легко')),
          DropdownMenuItem(value: 2, child: Text('2 - Легко')),
          DropdownMenuItem(value: 3, child: Text('3 - Средне')),
          DropdownMenuItem(value: 4, child: Text('4 - Сложно')),
          DropdownMenuItem(value: 5, child: Text('5 - Очень сложно')),
        ],
        onChanged: onChanged,
      ),
    ),
  );


  Widget buildDateButton({required String label, required VoidCallback onTap}) => Container(
    height: 56,
    decoration: BoxDecoration(
      color: theme.colorScheme.onSurface.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    ),
  );


  Future<DateTime?> pickDate(BuildContext context, DateTime initialDate) async {
    final theme = Theme.of(context); // Получаем текущую тему приложения

    return await showDatePicker(
      context: context,
      initialDate: initialDate, // Календарь откроется на уже выбранной дате
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: theme.colorScheme.onPrimary,               // Черный текст на кнопках и круге
              surface: theme.cardColor,              // Фон самого окошка календаря
              onSurface: theme.textTheme.bodyLarge?.color, // Цвет чисел и дней недели
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary, // Цвет кнопок
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

// Верхний бар с месяцем строго по центру (без накладывания)
  Widget buildTopBar() {
    final monthTitle = '$currentMonthName ${selectedDate.year}';

    // Ширина одной стандартной иконки-кнопки во Flutter обычно 48 пикселей
    //  две кнопки справа (48 * 2 = 96), делаем такой же пустой отступ слева для баланса
    const double buttonsWidth = 96.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Левый невидимый отступ для идеального центрирования текста
          const SizedBox(width: buttonsWidth),

          // Название месяца (занимает всё центральное пространство)
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: pickMonthAndYear,
                child: Text(
                  monthTitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // если экран совсем узкий,
                  // текст аккуратно сократится
                ),
              ),
            ),
          ),

          //Блок кнопок справа (ширина как раз около 96 пикселей)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  _showRulesDialog(context);
                },
                icon: Icon(Icons.help_outline, color: theme.colorScheme.onSurface),
                tooltip: 'Правила начисления звёзд',
              ),
              IconButton(
                onPressed: () {
                  addTasksBottomSheet();
                },
                icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //диалоговое окно
  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor, // Темный фон
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Text(
                'Правила начисления',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Выполняйте задачи, зарабатывайте звёзды и открывайте новые достижения!',
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Блок 1: Однодневные задачи
                _buildRuleRow(
                  icon: Icons.looks_one,
                  title: 'Обычные задачи (1 день)',
                  description: 'Вы получаете всю стоимость задачи сразу при её выполнении.',
                ),
                const SizedBox(height: 16),

                // Блок 2: Многодневные задачи
                _buildRuleRow(
                  icon: Icons.calendar_month,
                  title: 'Многодневные задачи',
                  description:
                      '• Каждый промежуточный день вы получаете по 1 ⭐ за поддержание привычки.\n'
                      '• В финальный день вам начисляется вся оставшаяся сумма от общей стоимости задачи!',
                ),
                const SizedBox(height: 12),

                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                const Text(
                  'Если вы снимете галочку с выполненной задачи, заработанные за этот день звёзды спишутся!',
                  style: TextStyle(color: Colors.redAccent, fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text(
                'Понятно',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

// Вспомогательный виджет для красивой строки правил начисления звезд
  Widget _buildRuleRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.amberAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style:  TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> pickMonthAndYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Выберите месяц',
    );

    if (picked != null) {
      setState(() {
        currentMonth = DateTime(picked.year, picked.month, 1);
        selectedDate = currentMonth;
      });

      loadMonthStats(currentMonth);
    }
  }


// Переключатель "Месяц / Неделя / День"
  Widget buildPeriodSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            buildSegmentButton(
              'Месяц',
              viewMode == ViewMode.month,
                  () {
                setState(() {
                  viewMode = ViewMode.month;
                });
              },
            ),
            buildSegmentButton(
              'Неделя',
              viewMode == ViewMode.week,
                  () {
                setState(() {
                  viewMode = ViewMode.week;
                });
              },
            ),
            buildSegmentButton(
              'День',
              viewMode == ViewMode.day,
                  () {
                setState(() {
                  viewMode = ViewMode.day;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void changeMonth(int offset) {
    setState(() {
      currentMonth = DateTime(
        currentMonth.year,
        currentMonth.month + offset,
        1,
      );
      selectedDate = currentMonth;
    });

    loadMonthStats(currentMonth);

  }


  Widget buildSegmentButton(String text, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

// Календарь месяца
  Widget buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(
        currentMonth.year, currentMonth.month);
    final firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday;
    final totalCells = daysInMonth + (firstWeekday - 1);
    final rows = (totalCells / 7).ceil();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            buildWeekdayRow(),
            const SizedBox(height: 4),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rows * 7,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - (firstWeekday - 2);
                  if (dayNumber <= 0 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime(
                      currentMonth.year, currentMonth.month, dayNumber);
                  return buildDayCell(date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //

  Widget buildWeekView() {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1)); // понедельник
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Expanded(
      child: Column(
        children: [
          // Заголовок недели + переключатели
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
                  onPressed: () => _changeWeek(-1),
                ),
                Column(
                  children: [
                    Text(
                      "${weekDays.first.day} - ${weekDays.last.day} ",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${monthNames[selectedDate.month]} ${selectedDate.year}",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                  onPressed: () => _changeWeek(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 7 дней недели
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekDays.map((date) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        selectedDate = date;
                      });
                      await loadTasks(date);
                      await loadDayStats(date);
                    },
                    child: buildWeekDayCell(date),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Список задач выбранного дня
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _dayTasks.isEmpty
                  ? const EmptyTasksWidget()
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _dayTasks.length,
                itemBuilder: (context, index) {
                  final task = _dayTasks[index];
                  return GestureDetector(
                    key: ValueKey(identityHashCode(task)),
                    onLongPress: () async {
                      // 1. Открываем меню действий
                      final String? action = await _showActionMenu(context, task);

                      if (action == 'edit') {
                        // 2. Ждем, пока пользователь отредактирует задачу
                        await addTasksBottomSheet(taskToEdit: task);
                        // 3. Обновляем главный экран (в режиме дня setState обновит всё сразу)
                        setState(() {});
                      } else if (action == 'delete') {
                        // 2. Удаляем из БД
                        await controller.deleteTask(task.id!);
                        await _refreshCurrentView();
                        setState(() {});
                      }
                    },
                      child: TaskRowWidget(
                      task: task,
                      onDelete: () async {
                        await controller.deleteTask(task.id!);
                        await _refreshCurrentView();
                      },
                      onChanged: (value) async {
                        if (value == null) return;
                        await controller.updateTaskProgress(
                          taskId: _dayTasks[index].id!,
                          date: selectedDate, //дата задачи которую отметили
                          completed: value,
                        );
                        await _refreshCurrentView();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeekDayCell(DateTime date) {
    final isSelected = date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final status = days[date];

    Color bgColor = theme.colorScheme.onSurface.withOpacity(0.08);
    if (isSelected) bgColor = AppColors.primary;
    else if (isToday) bgColor = AppColors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][date.weekday - 1],
            style: TextStyle(
              color: isSelected ? Colors.black : theme.colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isSelected ? Colors.black : theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (status != null)
            Icon(
              status.type == DayType.completed ? Icons.check_circle :
              status.type == DayType.warning ? Icons.warning_amber :
              Icons.error_outline,
              size: 14,
              color: isSelected ? Colors.black87 : theme.colorScheme.onSurface,
            ),
        ],
      ),
    );
  }

  void _changeWeek(int offset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: 7 * offset));
    });

    // Обновляем задачи для нового выбранного дня
    loadTasks(selectedDate);
    loadDayStats(selectedDate);
  }

  Widget buildDayView() {
    return Expanded(
      child: Column(
        children: [
          // Заголовок с выбором даты
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface, size: 32),
                  onPressed: () => _changeDay(-1),
                ),

                GestureDetector(
                  onTap: _pickDateInDayView,
                  child: Column(
                    children: [
                      Text(
                        "${selectedDate.day}",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${monthNames[selectedDate.month]} ${selectedDate.year}",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface, size: 32),
                  onPressed: () => _changeDay(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Прогресс выполнения
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildTodayProgress(),
          ),

          const SizedBox(height: 16),

          // Список задач
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _dayTasks.isEmpty
                  ? const EmptyTasksWidget()
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _dayTasks.length,
                itemBuilder: (context, index) {
                  final task = _dayTasks[index];
                  return GestureDetector(
                    key: ValueKey(identityHashCode(task)),
                    onLongPress: () async {
                      // 1. Открываем меню действий
                      final String? action = await _showActionMenu(context, task);

                      if (action == 'edit') {
                        // 2. Ждем, пока пользователь отредактирует задачу
                        await addTasksBottomSheet(taskToEdit: task);
                        // 3. Обновляем главный экран (в режиме дня setState обновит всё сразу)
                        setState(() {});
                      } else if (action == 'delete') {
                        // 2. Удаляем из БД
                        await controller.deleteTask(task.id!);
                        await _refreshCurrentView();
                        setState(() {});
                      }
                    },
                      child: TaskRowWidget(
                      task: task,
                      onDelete: () async {
                        await controller.deleteTask(_dayTasks[index].id!);
                        await _refreshCurrentView();
                      },
                      onChanged: (value) async {
                        if (value == null) return;

                        await controller.updateTaskProgress(
                          taskId: _dayTasks[index].id!,
                          date: selectedDate,      // передаём дату, на которой отметили
                          completed: value,
                        );

                        await _refreshCurrentView();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Смена дня на след.
  void _changeDay(int offset) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: offset));
    });

    loadTasks(selectedDate);
    loadDayStats(selectedDate);
  }

  // Выбор даты через календарь
  Future<void> _pickDateInDayView() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      await loadTasks(picked);
      await loadDayStats(picked);
    }
  }

  Widget buildWeekdayRow() {
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (e) =>
            Expanded(
              child: Center(
                child: Text(
                  e,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
      )
          .toList(),
    );
  }

  Widget buildDayCell(DateTime date) {
    final status = days[date];
    final isSelected = date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;

    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    Color bgColor;
    switch (status?.type) {
      case DayType.completed:
        bgColor = AppColors.success;
        break;
      case DayType.failed:
        bgColor = AppColors.failed;
        break;
      case DayType.warning:
        bgColor = AppColors.warning;
        break;
      default:
        bgColor = theme.colorScheme.onSurface.withOpacity(0.08);
    }

    if (isSelected) {
      bgColor = theme.colorScheme.onSurface.withOpacity(0.3);
    } else if (isToday) {
      bgColor = theme.colorScheme.onSurface.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedDate = date;
        });

        // сначала грузим
        await Future.wait([
          loadTasks(date),
          loadDayStats(date),
        ]);

        if (!mounted) return;

        // только потом показываем
        showDayTasksBottomSheet();
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (status != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (status.type == DayType.completed)
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                  if (status.type == DayType.failed)
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  if (status.type == DayType.warning)
                    Icon(Icons.error_outline, color: theme.colorScheme.onSurface, size: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }

  

  void showDayTasksBottomSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,               // позволяет full-screen
      backgroundColor: Colors.transparent,    // чтобы скругления работал
      enableDrag: true,
      builder: (context) {
        return DraggableScrollableSheet(
          // пресеты высоты: превью, средняя, full-screen
          initialChildSize: 0.35,  // первое положение (превью)
          minChildSize: 0.25,      // минимальная высота
          maxChildSize: 0.95,      // почти весь экран
          expand: false,

          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setBottomSheetState) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    // полоса для перетаскивания
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Задачи на день',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Divider(),
                      ],
                    ),

                    const SizedBox(height: 16),
                    buildTodayProgress(),

                    // контент, который может прокручиваться и уходить ниже экрана
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _dayTasks.length,
                          itemBuilder: (context, index) {
                            final task = _dayTasks[index]; // Выносим для читаемости кода

                            return GestureDetector(
                              // НАЧАЛО: Ловим долгое нажатие на карточку задачи
                              onLongPress: () async {
                                // Открываем меню действий и ждем, что выберет пользователь
                                final String? action = await _showActionMenu(context, task);

                                if (action == 'edit') {
                                  // Если выбрали редактировать — открываем наше обновленное окно
                                  // Добавляем await, чтобы код остановился и ждал,
                                  // пока addTasksBottomSheet закроется
                                  await addTasksBottomSheet(taskToEdit: task);
                                  // Когда окно редактирования закрылось
                                  // принудительно обновляем список задач на день
                                  await _refreshCurrentView();
                                  setBottomSheetState(() {});
                                } else if (action == 'delete') {
                                  // Если выбрали удалить — удаляем, обновляем базу
                                  // и перерисовываем текущий BottomSheet
                                  await controller.deleteTask(task.id!);
                                  await _refreshCurrentView();
                                  setBottomSheetState(() {});
                                }
                              },


                              child: TaskRowWidget(
                                task: task,
                                onDelete: () async {
                                  await controller.deleteTask(task.id!);
                                  await _refreshCurrentView();
                                  setBottomSheetState(() {});
                                },
                                onChanged: (value) async {
                                  if (value == null) return;

                                  await controller.updateTaskProgress(
                                    taskId: task.id!,
                                    date: selectedDate,      // передаём дату, на которой отметили
                                    completed: value,
                                  );

                                  await _refreshCurrentView();
                                  setBottomSheetState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
              },
            );
          },
        );
      },
    );
  }

  Future<String?> _showActionMenu(BuildContext context, Task task) {
    final theme = Theme.of(context); // Получаем текущую тему

    return showModalBottomSheet<String>(
      context: context,
      // Используем цвет карточки для фона шторки (он адаптируется под каждую тему)
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Адаптивный разделитель
              Divider(
                color: theme.colorScheme.onSurface.withOpacity(0.12),
                height: 1,
              ),
              ListTile(
                // Иконка теперь красится в цвет темы (золотой, бирюзовый или желтый)
                leading: Icon(Icons.edit, color: theme.colorScheme.primary),
                title: Text(
                  'Редактировать',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(context, 'edit');
                },
              ),
              ListTile(
                // Используем настроенный в вашей теме AppColors.failed через theme.colorScheme.error
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text(
                  'Удалить',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context, 'delete');
                },
              ),
            ],
          ),
        );
      },
    );
  }

// блок с % выполнения задач
  Widget buildTodayProgress() {
    final status = days[selectedDate];
    final done = status?.doneTasks ?? 0;
    final total = status?.totalTasks ?? 0;
    final percent = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$done/$total задач выполнено',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(percent * 100).round()}%',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Централизованный метод для пересчета статистики мотивационной карточки
  void _updateMotivationStats() {
    int activeDays = 0;
    int completedDays = 0;

    days.forEach((date, status) {
      // Если в этот день была хоть одна задача
      if (status.totalTasks > 0) {
        activeDays++;

        // Если все задачи в этот день выполнены
        if (status.doneTasks == status.totalTasks) {
          completedDays++;
        }
      }
    });

    activeDaysInMonth = activeDays;
    completedDaysInMonth = completedDays;
  }

  // мотивирующая карточка внизу страницы
  Widget buildMotivationCard() {
    // Динамический подсчет статистики прямо в момент рендеринга
    int activeDays = 0;
    int completedDays = 0;

    days.forEach((date, status) {
      // Фильтруем строго по текущему месяцу и году, чтобы избежать багов при переходе границ месяцев
      if (date.month == currentMonth.month && date.year == currentMonth.year) {
        if (status.totalTasks > 0) {
          activeDays++;
          if (status.doneTasks == status.totalTasks) {
            completedDays++;
          }
        }
      }
    });

    // Декларативное определение текстов и иконок для разных сценариев
    String title;
    String subtitle;
    IconData cardIcon;
    Color iconColor;

    if (activeDays == 0) {
      // Сценарий 1: Задач на месяц вообще нет
      title = 'В этом месяце пока нет активных дней. Время планировать!';
      subtitle = 'Каждая большая цель начинается с первой задачи.';
      cardIcon = Icons.calendar_today_rounded;
      iconColor = theme.colorScheme.onSurface;
    } else if (completedDays == 0) {
      // Сценарий 2: Задачи добавлены (например, в начале недели), но ещё не завершены
      title = 'Запланировано дней с задачами: $activeDays. Отличный старт!';
      subtitle = 'Продуктивные дни впереди! Сделай первый шаг и выполни задачу сегодня.';
      cardIcon = Icons.rocket_launch_rounded;
      iconColor = AppColors.primary;
    } else if (completedDays == activeDays) {
      // Сценарий 3: Идеальный результат (все активные дни завершены)
      title = 'Продуктивных дней: $completedDays из $activeDays! Идеальный результат!';
      subtitle = 'Потрясающе! Ты закрыл абсолютно все запланированные задачи!';
      cardIcon = Icons.emoji_events_rounded;
      iconColor = Colors.amber;
    } else {
      // Сценарий 4: Обычный рабочий процесс (часть дней выполнена, часть в процессе)
      title = 'Продуктивных дней в этом месяце: $completedDays из $activeDays!';
      subtitle = 'Хороший темп! Продолжай в том же духе, у тебя всё получается!';
      cardIcon = Icons.star_rounded;
      iconColor = AppColors.primary;
    }

    // 3. Возвращаем ваш оригинальный виджет с новыми динамическими данными
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.onSurface),
          boxShadow: const [
            BoxShadow(color: Colors.black26),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(cardIcon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}