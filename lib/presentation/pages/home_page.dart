import 'package:flutter/material.dart';
import 'package:starplan/presentation/pages/profile_page.dart';

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

class HomePageState extends State<HomePage> {
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime selectedDate = DateTime.now();
  int selectedDifficulty = 1;

  double currentSliderValue = 1.0;

  int currentTabIndex = 0;
  late final List<Widget> items = [buildTaskRow('Задание 1'), Divider(),  buildTaskRow('Задание 2'),Divider(),
    buildTaskRow('Задание 3'), Divider(), buildTaskRow('Задание 4')];

  bool isEditMode = false;

// Заглушка для статистики по дням ( потом брать из БД)
  final Map<DateTime, DayStatus> days = {};

  @override
  void initState() {
    super.initState();
    initMockDays();
  }

  void initMockDays() {
    // первый день текущего месяца
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(base.year, base.month);

    for (int i = 0; i < daysInMonth; i++) {
      final d = DateTime(base.year, base.month, i + 1);

      // TODO: из бд
      // пример логики: будни completed, выходные warning, 15‑е failed
      final weekday = d.weekday; // 1 = Пн ... 7 = Вс
      DayType type;
      if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
        type = DayType.warning;
      } else if (d.day == 15) {
        type = DayType.failed;
      } else {
        type = DayType.completed;
      }

      days[d] = DayStatus(
        doneTasks: type == DayType.completed ? 5 : (type == DayType.failed ? 1 : 3),
        totalTasks: 5,
        type: type,
      );
    }
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
              buildCalendar(),
              const SizedBox(height: 8),
              buildMotivationCard(),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),

    );
  }


  void addTasksBottomSheet() {
    // Локальное состояние
    bool isCompleted = false;
    int stars = 0;
    DateTime? startDate, endDate;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.93,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF020B3B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -10))],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Отмена',
                        style: TextStyle(
                          color: Color(0xFFFFC94B),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.left,),
                      Divider(),
                      Text(
                        'Задание',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Divider(),
                      Text('Добавить',
                        style: TextStyle(
                          color: Color(0xFFFFC94B),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      buildSectionTitle('Основная информация'),
                      // Название
                      textField('Название задачи'),
                      const SizedBox(height: 20),

                      // Описание
                      textField('Описание (необязательно)'),
                      const SizedBox(height: 24),

                      buildSectionTitle('Сложность'),
                      buildDifficultyDropdown(selectedDifficulty, setSheetState),
                      const SizedBox(height: 24),

                      buildSectionTitle('Сроки выполнения'),
                      buildDatePickerRow(startDate, endDate, setSheetState),
                      const SizedBox(height: 24),

                      buildSectionTitle('Ожидаемая награда'),
                      buildStarsSelector(stars, setSheetState),
                      const SizedBox(height: 24),
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

  Widget buildDifficultyDropdown(int value, StateSetter setState) => Container(
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
        onChanged: (value) => setState(() => selectedDifficulty = value!),
      ),
    ),
  );

  Widget buildDatePickerRow(DateTime? start, DateTime? end, StateSetter setState) => IntrinsicHeight(
    child: Row(
      children: [
        Expanded(
          child: buildDateButton(
            label: start == null ? 'Начало' : '${start.day}.${start.month}.${start.year}',
            onTap: () => pickDate(setState, startDate: start),
          ),
        ),
        Container(width: 2, height: 48, color: Colors.white.withOpacity(0.4), margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(
          child: buildDateButton(
            label: end == null ? 'Конец' : '${end.day}.${end.month}.${end.year}',
            onTap: () => pickDate(setState, endDate: end),
          ),
        ),
      ],
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
    padding: const EdgeInsets.all(16),
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

  Future<void> pickDate(StateSetter setState, {DateTime? startDate, DateTime? endDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      // TODO: Логика установки даты
    }
  }

  Widget textField(String hint){
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
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
      ),
    );
  }


// Верхний бар с месяцем и кнопками меню/добавить
  Widget buildTopBar() {
    final monthTitle = 'Октябрь 2025';
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
            buildSegmentButton('Месяц', true, () {}),
            buildSegmentButton('Неделя', false, () {}),
            buildSegmentButton('День', false, () {
// TODO: перейти к детальному дневному виду
            }),
          ],
        ),
      ),
    );
  }

  Widget buildTaskRow(String title) {
    return MenuAnchor(
      // пункты контекстного меню для задачи
      menuChildren: [
        MenuItemButton(
          child: const Text('Изменить'),
          onPressed: () {
            // TODO: открыть экран изменения
          },
        ),
        MenuItemButton(
          child: const Text(
            'Удалить',
            style: TextStyle(color: Colors.red),
          ),
          onPressed: () {
            // TODO: удалить задачу
          },
        ),
      ],

      // builder рисует строку задачи
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return GestureDetector(
          onLongPress: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open(); // ← по долгому нажатию открыть меню
            }
          },
          child: child,
        );
      },

      // виджет строки задачи
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Checkbox(
              value: false,
              activeColor: const Color(0xFFFFC94B),
              checkColor: Colors.black,
              onChanged: (bool? value) {
                // TODO: отметить задачу выполненной
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
    final isSelected =
        date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;

    Color bgColor;
    switch (status?.type) {
      case DayType.completed:
        bgColor = const Color(0xFF00B894); // зелёный
        break;
      case DayType.failed:
        bgColor = const Color(0xFFB71359); // красный
        break;
      case DayType.warning:
        bgColor = const Color(0xFF1E90FF); // синий
        break;
      default:
        bgColor = Colors.white.withOpacity(0.08);
    }

    if (isSelected) {
      bgColor = Colors.white.withOpacity(0.3);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDate = date;
          showDayTasksBottomSheet();
        });
// TODO: открыть детали выбранного дня
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.transparent,
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
                    const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 16),
                  if (status.type == DayType.failed)
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 16),
                  if (status.type == DayType.warning)
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void showDayTasksBottomSheet() {
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
                        itemCount: items.length,
                        itemBuilder: (context, index){
                          return items[index];
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
            'Сегодня: $done/$total задач выполнено',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white),
          boxShadow: [BoxShadow(color: Colors.black26)]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.star, color: Color(0xFFFFC94B)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ты уже выполнил 18 дней в этом месяце!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Продолжай в том же духе!',
                    style: TextStyle(
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