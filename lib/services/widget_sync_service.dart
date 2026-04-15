import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';

class WidgetSyncService {
  static const String androidWidgetProvider = 'HabitWidgetProvider';

  static const String _kTodayDone = 'widget_today_done';
  static const String _kTodayTotal = 'widget_today_total';
  static const String _kTopStreakTitle = 'widget_top_streak_title';
  static const String _kTopStreakValue = 'widget_top_streak_value';
  static const String _kLastUpdated = 'widget_last_updated';

  Future<SharedPreferences>? _prefsFuture;
  DateTime? _lastSyncAt;

  Future<void> syncFromState({
    required List<Habit> habits,
    required List<HabitLog> logs,
  }) async {
    final now = DateTime.now();
    if (_lastSyncAt != null &&
        now.difference(_lastSyncAt!) < const Duration(milliseconds: 300)) {
      return;
    }
    _lastSyncAt = now;

    final activeHabits = habits.where((habit) => habit.isActive).toList();
    final today = HabitLog.normalizeDate(DateTime.now());

    final Map<String, int> todayDoneCounts = {};
    for (final log in logs) {
      if (log.status != 'done') continue;
      if (HabitLog.normalizeDate(log.loggedAt) != today) continue;
      todayDoneCounts.update(log.habitId, (value) => value + 1, ifAbsent: () => 1);
    }

    int todayDone = 0;
    for (final habit in activeHabits) {
      final count = todayDoneCounts[habit.id] ?? 0;
      if (count >= habit.target) {
        todayDone++;
      }
    }

    Habit? topStreakHabit;
    for (final habit in activeHabits) {
      if (topStreakHabit == null ||
          habit.currentStreak > topStreakHabit.currentStreak) {
        topStreakHabit = habit;
      }
    }

    final topStreakTitle = topStreakHabit?.title ?? 'No habits yet';
    final topStreakValue = topStreakHabit?.currentStreak ?? 0;
    final lastUpdated = now.toIso8601String();

    // Store values in SharedPreferences so Android widget can read them directly.
    final prefs = await (_prefsFuture ??= SharedPreferences.getInstance());
    await prefs.setInt(_kTodayDone, todayDone);
    await prefs.setInt(_kTodayTotal, activeHabits.length);
    await prefs.setString(_kTopStreakTitle, topStreakTitle);
    await prefs.setInt(_kTopStreakValue, topStreakValue);
    await prefs.setString(_kLastUpdated, lastUpdated);

    // Mirror values in home_widget storage and request a widget refresh.
    await HomeWidget.saveWidgetData<int>(_kTodayDone, todayDone);
    await HomeWidget.saveWidgetData<int>(_kTodayTotal, activeHabits.length);
    await HomeWidget.saveWidgetData<String>(_kTopStreakTitle, topStreakTitle);
    await HomeWidget.saveWidgetData<int>(_kTopStreakValue, topStreakValue);
    await HomeWidget.saveWidgetData<String>(_kLastUpdated, lastUpdated);

    await HomeWidget.updateWidget(name: androidWidgetProvider);
  }
}
