import 'package:flutter/material.dart';
import 'package:starplan/core/constants/app_colors.dart';

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
    return Scaffold(
// Фон можно задать через контейнер с BoxDecoration
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

  void addTasksBottomSheet() {
    // Локальное состояние внутри bottom sheet
    String? titleError;

    // Устанавливаем выбранную на главном экране дату по умолчанию
    DateTime? startDate = selectedDate;
    DateTime? endDate = selectedDate;

    int selectedDifficulty = 1;

    // Считаем начальные звёзды (1 день * сложность 1 = 1 звезда)
    int calculatedStars = selectedDifficulty * 1;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    // Функция для пересчёта звёзд
    void updateStars(StateSetter setSheetState) {
      DateTime taskStart = startDate ?? selectedDate;
      DateTime taskEnd = endDate ?? taskStart;

      // Если конец раньше начала — меняем местами
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

    showModalBottomSheet(
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
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Text(
                        'Новое задание',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: titleController.text.trim().isEmpty
                            ? null  // отключаем нажатие
                            : () async {
                          // Валидация
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            setSheetState(() {
                              titleError = 'Введите название задачи';
                            });
                            return;
                          }

                          setSheetState(() {
                            titleError = null;
                          });

                          final description = descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim();

                          DateTime taskStart = startDate ?? selectedDate;
                          DateTime taskEnd = endDate ?? taskStart;

                          // Корректируем порядок дат
                          if (taskEnd.isBefore(taskStart)) {
                            final tmp = taskStart;
                            taskStart = taskEnd;
                            taskEnd = tmp;
                          }

                          final days = taskEnd.difference(taskStart).inDays + 1;
                          final stars = selectedDifficulty * days;

                          // Сохраняем в базу
                          await controller.createTask(
                            title: title,
                            description: description,
                            difficulty: selectedDifficulty,
                            startDate: taskStart,
                            endDate: taskEnd,
                            stars: stars,
                          );

                          // Обновляем интерфейс
                          await Future.wait([
                            loadTasks(selectedDate),
                            loadDayStats(selectedDate),
                            loadMonthStats(currentMonth),
                          ]);

                          if (!mounted) return;
                          Navigator.pop(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: const Text(
                            'Добавить',
                            style: TextStyle(
                              color: AppColors.primary,
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

                      // Название
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Название задачи',
                          labelStyle: const TextStyle(color: Colors.white70),
                          errorText: titleError,
                          errorStyle: const TextStyle(color: Colors.orangeAccent),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            titleError = value.trim().isEmpty ? 'Обязательное поле' : null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Описание
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Описание (необязательно)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
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
                          // Передаем текущую дату начала или выбранную на экране
                          final picked = await pickDate(context, startDate ?? selectedDate);
                          if (picked != null) {
                            setSheetState(() {
                              startDate = picked;
                            });
                            updateStars(setSheetState);
                          }
                        },
                        onPickEnd: () async {
                          final picked = await pickDate(context, startDate ?? selectedDate);
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
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              '$calculatedStars звёзд',
                              style: const TextStyle(
                                color: Colors.white,
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
          style: const TextStyle(
            color: Colors.white,
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
              color: Colors.white.withOpacity(0.4),
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
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF020C42),
        style: const TextStyle(color: Colors.white, fontSize: 16),
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
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
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


// Передаем текущую установленную дату в качестве начальной для календаря
  Future<DateTime?> pickDate(BuildContext context, DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial, // <-- Откроется на уже выбранном дне
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }



// Верхний бар с месяцем и кнопками меню/добавить
  Widget buildTopBar() {
    final monthTitle = '$currentMonthName ${selectedDate.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // TODO: открыть боковое меню
            },
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: pickMonthAndYear,
                child: Text(
                  monthTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            ),
          ),
          IconButton(
            onPressed: () {
              addTasksBottomSheet();
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
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
          color: Colors.white.withOpacity(0.06),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
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
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => _changeWeek(-1),
                ),
                Column(
                  children: [
                    Text(
                      "${weekDays.first.day} - ${weekDays.last.day} ",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "${monthNames[selectedDate.month]} ${selectedDate.year}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
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
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _dayTasks.isEmpty
                  ? const EmptyTasksWidget()
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _dayTasks.length,
                itemBuilder: (context, index) {
                  return TaskRowWidget(
                    task: _dayTasks[index],
                    onDelete: () async {
                      await controller.deleteTask(_dayTasks[index].id!);
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

    Color bgColor = Colors.white.withOpacity(0.08);
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
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
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
              color: isSelected ? Colors.black87 : Colors.white70,
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
                  icon: const Icon(Icons.chevron_left, color: Colors.white, size: 32),
                  onPressed: () => _changeDay(-1),
                ),

                GestureDetector(
                  onTap: _pickDateInDayView,
                  child: Column(
                    children: [
                      Text(
                        "${selectedDate.day}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${monthNames[selectedDate.month]} ${selectedDate.year}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white, size: 32),
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
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _dayTasks.isEmpty
                  ? const EmptyTasksWidget()
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _dayTasks.length,
                itemBuilder: (context, index) {
                  return TaskRowWidget(
                    task: _dayTasks[index],
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
                    color: Colors.white.withOpacity(0.7),
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
        bgColor = Colors.white.withOpacity(0.08);
    }

    if (isSelected) {
      bgColor = Colors.white.withOpacity(0.3);
    } else if (isToday) {
      bgColor = Colors.white.withOpacity(0.15);
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
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: const TextStyle(
                color: Colors.white,
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
                    const Icon(Icons.error_outline, color: Colors.white, size: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }

  

  void showDayTasksBottomSheet() { //возможно улучшение?
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
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        const Expanded(
                          child: Text(
                            'Задачи на день',
                            style: TextStyle(
                              color: Colors.white,
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
                            return TaskRowWidget(
                              task: _dayTasks[index],
                              onDelete: () async {
                                await controller.deleteTask(_dayTasks[index].id!);
                                await _refreshCurrentView();
                                setBottomSheetState(() {});
                              },
                              onChanged: (value) async {
                                if (value == null) return;

                                await controller.updateTaskProgress(
                                  taskId: _dayTasks[index].id!,
                                  date: selectedDate,      // передаём дату, на которой отметили
                                  completed: value,
                                );

                                await _refreshCurrentView();
                                setBottomSheetState(() {});
                              },
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
            '$done/$total задач выполнено', // TODO: подгружать количество задач из бд
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(percent * 100).round()}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.1),
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
      iconColor = Colors.white70;
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
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
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