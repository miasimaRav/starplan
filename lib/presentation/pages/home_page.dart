import 'package:flutter/material.dart';
import 'package:starplan/presentation/pages/profile_page.dart';

import '../../data/database.dart';
import '../../data/models/task_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}
enum ViewMode { month, week, day }

class HomePageState extends State<HomePage> {
  ViewMode viewMode = ViewMode.month; //переменная для контроля просмотра дат
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime selectedDate = DateTime.now();
  int selectedDifficulty = 1;
  // сколько дней в месяце выполнено полностью
  int completedDaysInMonth = 0;

// сколько дней в месяце вообще имеют задачи
  int activeDaysInMonth = 0;
  List<String> monthNames = [
    '', // заглушка для индекса 0
    'Января',
    'Февраля',
    'Марта',
    'Апреля',
    'Мая',
    'Июня',
    'Июля',
    'Августа',
    'Сентября',
    'Октября',
    'Ноября',
    'Декабря',
  ];

  //late final currentMonthName = monthNames[selectedDate.month];
  String get currentMonthName => monthNames[currentMonth.month];

  List<Task> _dayTasks = [];

  double currentSliderValue = 1.0;

  int currentTabIndex = 0;
  // late final List<Widget> items = [buildTaskRow(Task.ti 'Задание 1'), Divider(),  buildTaskRow('Задание 2'),Divider(),
  //   buildTaskRow('Задание 3'), Divider(), buildTaskRow('Задание 4')];

  bool isEditMode = false;

// Заглушка для статистики по дням ( потом брать из БД)
  final Map<DateTime, DayStatus> days = {};

  int todayDoneTasks = 0;
  int todayTotalTasks = 0;

  @override
  void initState() {
    super.initState();
    loadDayStats(DateTime.now());
    loadMonthStats(currentMonth); // Добавляем загрузку статистики месяца из БД для начальных цветов
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

  Future<void> loadTasksForDate(DateTime date) async {
    // Для "одного дня" делаем диапазон [00:00; 23:59]
    final start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final tasks = await DatabaseHelper.instance.getTasksBetweenDates(
      start: start,
      end: end,
    );

    if (!mounted) return;
    setState(() {
      _dayTasks = tasks;
    });
  }

  Future<void> loadDayStats(DateTime date) async {
    final stats = await DatabaseHelper.instance.getTasksCountForDate(date);

    if (!mounted) return;
    setState(() {
      todayDoneTasks = stats['done'] ?? 0;
      todayTotalTasks = stats['total'] ?? 0;
    });
  }



  void addTasksBottomSheet() {
    // Локальное состояние внутри bottom sheet
    String? titleError;
    DateTime? startDate;
    DateTime? endDate;
    int selectedDifficulty = 1;
    int calculatedStars = 0;

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
              color: Color(0xFF020B3B),
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
                            color: Color(0xFFFFC94B),
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
                          await DatabaseHelper.instance.insertTask(
                            title: title,
                            description: description,
                            difficulty: selectedDifficulty,
                            startDate: taskStart,
                            endDate: taskEnd,
                            stars: stars,
                            completed: false,
                          );

                          // Обновляем интерфейс
                          await Future.wait([
                            loadTasksForDate(selectedDate),
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
                              color: Color(0xFFFFC94B),
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
                            borderSide: const BorderSide(color: Color(0xFFFFC94B), width: 2),
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
                            borderSide: const BorderSide(color: Color(0xFFFFC94B), width: 2),
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
                          final picked = await pickDate(context);
                          if (picked != null) {
                            setSheetState(() {
                              startDate = picked;
                            });
                            updateStars(setSheetState);
                          }
                        },
                        onPickEnd: () async {
                          final picked = await pickDate(context);
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
                            const Icon(Icons.star, color: Color(0xFFFFC94B), size: 28),
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
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
    });
  }

  int calculateStars({
    required int difficulty,
    required DateTime start,
    required DateTime end,
  }) {
    final days = end.difference(start).inDays + 1; // включая стартовый день
    return difficulty * days;
  }


  Future<void> loadMonthStats(DateTime month) async {
    // первый и последний день месяца
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // получить агрегированную статистику по дням
    // ожидается формат:
    // {
    //   DateTime(yyyy-mm-dd): { done: int, total: int }
    // }
    final stats = await DatabaseHelper.instance.getMonthDayStats(
      start: start,
      end: end,
    );

    int completed = 0;
    int active = 0;

    final Map<DateTime, DayStatus> newDays = {};

    stats.forEach((date, value) {
      final done = value['done'] ?? 0;
      final total = value['total'] ?? 0;

      if (total > 0) {
        active++;

        DayType type;
        if (done == total) {
          completed++;
          type = DayType.completed;
        } else if (done == 0) {
          type = DayType.failed;
        } else {
          type = DayType.warning;
        }

        newDays[date] = DayStatus(
          doneTasks: done,
          totalTasks: total,
          type: type,
        );
      }
    });

    if (!mounted) return;

    setState(() {
      completedDaysInMonth = completed;
      activeDaysInMonth = active;
      days
        ..clear()
        ..addAll(newDays);
    });
  }

  Widget buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Color(0xFFFFC94B),
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
          child: Text(label, style: const TextStyle(color: Color(0xFFFFC94B), fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    ),
  );

  Widget buildStarsSelector(int currentStars, StateSetter setState) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              'Звезды ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 150,
                child:
                TextFormField(
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    label: Text('100'),
                    labelStyle: const TextStyle(color: Colors.white),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFFC94B), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    enabled: false,
                  ),
                )
            )
          ]
      )
  );

  Future<DateTime?> pickDate(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020), // ← ключевая строка
      lastDate: DateTime(2100),
    );
  }


  Widget textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
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

  Widget buildCalendarWrapper() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        if (details.primaryVelocity! < 0) {
          // свайп влево - следующий месяц
          changeMonth(1);
        } else if (details.primaryVelocity! > 0) {
          // свайп вправо - предыдущий месяц
          changeMonth(-1);
        }
      },
      child: buildCalendar(),
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


  Widget buildTaskRow(Task task) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          child: const Text('Изменить'),
          onPressed: () {
            // TODO: открыть экран редактирования задачи
          },
        ),
        MenuItemButton(
          child: const Text(
            'Удалить',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () async {
            // Удаляем задачу из базы
            await DatabaseHelper.instance.deleteTask(task.id!);
            // Обновляем задачи и статистику
            await loadTasksForDate(selectedDate);
            await loadDayStats(selectedDate);
            await loadMonthStats(currentMonth);
          },
        ),
      ],
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return GestureDetector(
          onLongPress: () {
            controller.isOpen ? controller.close() : controller.open();
          },
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Checkbox(
              value: task.completed,
              onChanged: (value) async {
                await DatabaseHelper.instance.updateTaskCompleted(
                  task.id!,
                  value ?? false,
                );
                await loadTasksForDate(selectedDate);
                await loadDayStats(selectedDate);
                await loadMonthStats(currentMonth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSegmentButton(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFC94B)
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

  Widget buildWeekView() {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1)); // Пн
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            buildWeekdayRow(),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekDays.map((date) => Expanded(child: buildDayCell(date))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildDayView() {
    // Загружаем данные, если ещё не загружены
    // (на случай, если перешли в режим "День" без предварительного выбора)
    if (_dayTasks.isEmpty && todayTotalTasks == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadTasksForDate(selectedDate);
        loadDayStats(selectedDate);
      });
    }

    final String dayTitle =
        "${selectedDate.day} ${monthNames[selectedDate.month]} ${selectedDate.year}";

    return Expanded(
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Заголовок дня
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Можно добавить кнопку "Добавить задачу"
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFFFC94B), size: 32),
                  onPressed: addTasksBottomSheet,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Прогресс
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildTodayProgress(),
          ),

          const SizedBox(height: 20),

          // Список задач или пустое состояние
          Expanded(
            child: _dayTasks.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty, size: 70, color: Colors.white38),
                  SizedBox(height: 20),
                  Text(
                    "На этот день задач пока нет",
                    style: TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Добавьте задание с помощью кнопки «+»",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                itemCount: _dayTasks.length,
                itemBuilder: (context, index) {
                  return buildTaskRow(_dayTasks[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
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
        bgColor = const Color(0xFF00B894);
        break;
      case DayType.failed:
        bgColor = const Color(0xFFB71359);
        break;
      case DayType.warning:
        bgColor = const Color(0xFF1E90FF);
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
          loadTasksForDate(date),
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
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF020B3B),
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
                            final task = _dayTasks[index];
                            return buildTaskRow(task); // TODO: добавить полное описание задачи
                          },
                        ),
                      )

                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget tasksDay() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF020B3B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              // Полоса для перетаскивания
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
              const Text(
                'Задачи на день',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Прогресс выполнения
              buildTodayProgress(),

              // Список задач
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    itemCount: _dayTasks.length,
                    itemBuilder: (context, index) {
                      final task = _dayTasks[index];
                      return buildTaskRow(task); // передаем Task
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                  Color(0xFFFFC94B)),
            ),
          ),
        ],
      ),
    );
  }

// карточка внизу
  Widget buildMotivationCard() {
    if (activeDaysInMonth == 0) {
      // если в месяце нет задач — карточку не показываем
      return const SizedBox.shrink();
    }

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
            const Icon(Icons.star, color: Color(0xFFFFC94B)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ты выполнил $completedDaysInMonth из $activeDaysInMonth дней в этом месяце',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    completedDaysInMonth == activeDaysInMonth
                        ? 'Идеальный месяц 🔥'
                        : 'Продолжай в том же духе!',
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

class LongPressListItem extends StatelessWidget {
  final Widget item;
  final VoidCallback onLongPress;

  const LongPressListItem({
    required this.item,
    required this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      child: item,
    );
  }
}


enum DayType { completed, failed, warning }

class DayStatus {
  final int doneTasks;
  final int totalTasks;
  final DayType type;

  DayStatus({
    required this.doneTasks,
    required this.totalTasks,
    required this.type,
  });
}