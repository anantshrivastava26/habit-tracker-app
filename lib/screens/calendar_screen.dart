import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/habit_provider.dart';
import '../widgets/neu_box.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = HabitLog.normalizeDate(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Map<DateTime, List<HabitLog>> eventMap = {};
    for (final log in provider.logs) {
      eventMap.putIfAbsent(HabitLog.normalizeDate(log.loggedAt), () => [])
          .add(log);
    }

    List<HabitLog> getEventsForDay(DateTime day) =>
        eventMap[HabitLog.normalizeDate(day)] ?? [];

    final habits = provider.habits;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: NeuColors.textPrimary(isDark)),
        ),
      ),
      body: Column(
        children: [
          // ── Calendar ──────────────────────────────────────────────────
          TableCalendar<HabitLog>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2099),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: getEventsForDay,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = HabitLog.normalizeDate(selected);
                _focusedDay = focused;
              });
            },
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: NeuColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: NeuColors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: NeuColors.success,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              outsideDaysVisible: false,
              defaultTextStyle:
                  TextStyle(color: NeuColors.textPrimary(isDark)),
              weekendTextStyle:
                  TextStyle(color: Colors.red.shade400),
              todayTextStyle: TextStyle(
                  color: NeuColors.textPrimary(isDark),
                  fontWeight: FontWeight.bold),
              selectedTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: NeuColors.textPrimary(isDark),
              ),
              leftChevronIcon: Icon(Icons.chevron_left,
                  color: NeuColors.textPrimary(isDark)),
              rightChevronIcon: Icon(Icons.chevron_right,
                  color: NeuColors.textPrimary(isDark)),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                  color: NeuColors.textSecondary(isDark), fontSize: 12),
              weekendStyle:
                  TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              color: NeuColors.textSecondary(isDark)
                  .withValues(alpha: 0.15),
              height: 1,
            ),
          ),

          // ── Selected day habits ───────────────────────────────────────
          Expanded(
            child: habits.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeuBox(
                          style: NeuStyle.raised,
                          borderRadius: 22,
                          depth: 6,
                          width: 76,
                          height: 76,
                          child: Icon(
                            Icons.event_available_outlined,
                            size: 36,
                            color: NeuColors.textSecondary(isDark)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No habits created yet',
                          style: TextStyle(
                              color: NeuColors.textSecondary(isDark)),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          DateFormat('EEEE, MMMM d')
                              .format(_selectedDay),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: NeuColors.textPrimary(isDark),
                          ),
                        ),
                      ),
                      ...habits.map((habit) {
                        final isDone = provider.isCompletedOnDate(
                          habit.id,
                          _selectedDay,
                        );
                        return _HabitDayItem(
                          habit: habit,
                          isDone: isDone,
                          onToggle: () =>
                              provider.toggleForDate(habit.id, _selectedDay),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _HabitDayItem extends StatelessWidget {
  final Habit habit;
  final bool isDone;
  final Future<void> Function() onToggle;

  const _HabitDayItem({
    required this.habit,
    required this.isDone,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuBox(
        style: NeuStyle.raised,
        borderRadius: 14,
        depth: 4,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            NeuBox(
              style: NeuStyle.pressed,
              borderRadius: 12,
              depth: 3,
              width: 44,
              height: 44,
              child: Icon(
                IconData(habit.icon, fontFamily: 'MaterialIcons'),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: NeuColors.textPrimary(isDark)),
                  ),
                  Text(
                    habit.category,
                    style: TextStyle(
                        fontSize: 12,
                        color: NeuColors.textSecondary(isDark)),
                  ),
                ],
              ),
            ),
            NeuButton(
              onTap: onToggle,
              borderRadius: 12,
              depth: 3,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: isDone
                        ? NeuColors.success
                        : NeuColors.textSecondary(isDark),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDone ? 'Done' : 'Mark',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDone
                          ? NeuColors.success
                          : NeuColors.textSecondary(isDark),
                      fontWeight: FontWeight.w600,
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
