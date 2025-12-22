import 'package:flutter/material.dart';

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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime.now();
  int _currentTabIndex = 0;
  late final List<Widget> items = [_buildTaskRow('Задание 1'), Divider(),  _buildTaskRow('Задание 2'),Divider(),
    _buildTaskRow('Задание 3'), Divider(), _buildTaskRow('Задание 4')];

  bool _isEditMode = false;

// Заглушка для статистики по дням ( потом брать из БД)
  final Map<DateTime, _DayStatus> _days = {};

  @override
  void initState() {
    super.initState();
    _initMockDays();
  }

  void _initMockDays() {
    // первый день текущего месяца
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(base.year, base.month);

    for (int i = 0; i < daysInMonth; i++) {
      final d = DateTime(base.year, base.month, i + 1);

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

      _days[d] = _DayStatus(
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
              _buildTopBar(),
              const SizedBox(height: 8),
              _buildPeriodSwitch(),
              const SizedBox(height: 8),
              _buildCalendar(),
              const SizedBox(height: 8),
              _buildMotivationCard(),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
        // TODO: переход на страницу добавления задачи / дня
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

// Верхний бар с месяцем и кнопками меню/добавить
  Widget _buildTopBar() {
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
// TODO: переход на экран добавления чего‑то глобального
            },
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

// Переключатель "Месяц / Неделя / День"
  Widget _buildPeriodSwitch() {
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
            _buildSegmentButton('Месяц', true, () {}),
            _buildSegmentButton('Неделя', false, () {}),
            _buildSegmentButton('День', false, () {
// TODO: перейти к детальному дневному виду
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskRow(String title) {
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




  Widget _buildSegmentButton(String text, bool selected, VoidCallback onTap) {
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
  Widget _buildCalendar() {
    final daysInMonth = DateUtils.getDaysInMonth(
        _currentMonth.year, _currentMonth.month);
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final totalCells = daysInMonth + (firstWeekday - 1);
    final rows = (totalCells / 7).ceil();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            _buildWeekdayRow(),
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
                      _currentMonth.year, _currentMonth.month, dayNumber);
                  return _buildDayCell(date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayRow() {
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

  Widget _buildDayCell(DateTime date) {
    final status = _days[date];
    final isSelected =
        date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

    Color bgColor;
    switch (status?.type) {
      case DayType.completed:
        bgColor = const Color(0xFF00B894); // зелёный
        break;
      case DayType.failed:
        bgColor = const Color(0xFFB71359); // красный
        break;
      case DayType.warning:
        bgColor = const Color(0xFF1E90FF); // синий/фиолетовый
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
          _selectedDate = date;
          _showDayTasksBottomSheet();
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

  void _showDayTasksBottomSheet() {
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
                  _buildTodayProgress(),

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
  Widget _buildTodayProgress() {
    final status = _days[_selectedDate];
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
  Widget _buildMotivationCard() {
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

class _DayStatus {
  final int doneTasks;
  final int totalTasks;
  final DayType type;

  _DayStatus({
    required this.doneTasks,
    required this.totalTasks,
    required this.type,
  });
}