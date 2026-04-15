import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/widget_sync_service.dart';

class HabitProvider extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notifications;
  final WidgetSyncService _widgetSync;
  static const _uuid = Uuid();

  List<Habit> _habits = [];
  List<HabitLog> _logs = [];
  final Map<String, Map<DateTime, int>> _doneCountByHabitAndDate = {};
  final Map<String, Map<DateTime, List<HabitLog>>> _doneLogsByHabitAndDate = {};

  HabitProvider(this._storage, this._notifications, this._widgetSync);

  List<Habit> get habits => List.unmodifiable(_habits);
  List<HabitLog> get logs => List.unmodifiable(_logs);

  /// Active habits only
  List<Habit> get activeHabits => _habits.where((h) => h.isActive).toList();

  bool _nameExists(String name, {String? excludeId}) {
    final normalized = name.trim().toLowerCase();
    return _habits.any(
      (h) =>
          h.id != excludeId && h.title.trim().toLowerCase() == normalized,
    );
  }

  Habit? _habitById(String habitId) {
    try {
      return _habits.firstWhere((habit) => habit.id == habitId);
    } catch (_) {
      return null;
    }
  }

  int _countLogsOnDate(String habitId, DateTime date) {
    final targetDay = HabitLog.normalizeDate(date);
    return _doneCountByHabitAndDate[habitId]?[targetDay] ?? 0;
  }

  List<HabitLog> _logsForDate(String habitId, DateTime date) {
    final targetDay = HabitLog.normalizeDate(date);
    final logs = _doneLogsByHabitAndDate[habitId]?[targetDay];
    if (logs == null) return [];
    return List<HabitLog>.from(logs);
  }

  void _rebuildLogIndexes() {
    _doneCountByHabitAndDate.clear();
    _doneLogsByHabitAndDate.clear();
    for (final log in _logs) {
      _indexLog(log);
    }
  }

  List<DateTime> _doneDatesForHabit(String habitId) {
    return (_doneLogsByHabitAndDate[habitId]?.keys.toList() ?? [])..sort();
  }

  int _calculateCurrentStreak(List<DateTime> doneDates) {
    if (doneDates.isEmpty) return 0;

    final today = HabitLog.normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final doneDateSet = doneDates.toSet();
    final lastDate = doneDates.last;

    if (lastDate.isBefore(yesterday)) return 0;

    int streak = 0;
    var cursor = lastDate;
    while (doneDateSet.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _indexLog(HabitLog log) {
    if (log.status != 'done') return;
    final day = HabitLog.normalizeDate(log.loggedAt);
    final counts = _doneCountByHabitAndDate.putIfAbsent(log.habitId, () => {});
    counts.update(day, (value) => value + 1, ifAbsent: () => 1);

    final perHabitLogs =
        _doneLogsByHabitAndDate.putIfAbsent(log.habitId, () => {});
    final dayLogs = perHabitLogs.putIfAbsent(day, () => []);
    dayLogs.add(log);
    dayLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  void _removeLogFromIndexes(HabitLog log) {
    if (log.status != 'done') return;
    final day = HabitLog.normalizeDate(log.loggedAt);

    final counts = _doneCountByHabitAndDate[log.habitId];
    if (counts != null) {
      final nextCount = (counts[day] ?? 1) - 1;
      if (nextCount > 0) {
        counts[day] = nextCount;
      } else {
        counts.remove(day);
      }
      if (counts.isEmpty) {
        _doneCountByHabitAndDate.remove(log.habitId);
      }
    }

    final perHabitLogs = _doneLogsByHabitAndDate[log.habitId];
    final dayLogs = perHabitLogs?[day];
    if (dayLogs != null) {
      dayLogs.removeWhere((entry) => entry.id == log.id);
      if (dayLogs.isEmpty) {
        perHabitLogs?.remove(day);
      }
      if (perHabitLogs != null && perHabitLogs.isEmpty) {
        _doneLogsByHabitAndDate.remove(log.habitId);
      }
    }
  }

  void load() {
    _habits = _storage.loadHabits();
    _logs = _storage.loadLogs();
    _rebuildLogIndexes();
    // On load, check if any streaks need resetting due to missed days
    _checkAndResetStreaks();
    unawaited(_syncWidget());
    notifyListeners();
  }

  Future<void> _syncWidget() async {
    try {
      await _widgetSync.syncFromState(habits: _habits, logs: _logs);
    } catch (_) {
      // Keep widget sync failures isolated from app UX.
    }
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    if (_nameExists(habit.title)) {
      throw ArgumentError('A habit with this name already exists.');
    }

    final h = habit.copyWith(id: habit.id.isEmpty ? _uuid.v4() : habit.id);
    _habits.add(h);
    notifyListeners();

    try {
      await _storage.saveHabit(h);
      if (h.reminderTime != null) {
        await _notifications.scheduleHabitReminder(h);
      }
      await _syncWidget();
    } catch (_) {
      // Keep the UI responsive even if storage or scheduling fails.
    }
  }

  Future<void> updateHabit(Habit updated) async {
    final idx = _habits.indexWhere((h) => h.id == updated.id);
    if (idx == -1) return;

    if (_nameExists(updated.title, excludeId: updated.id)) {
      throw ArgumentError('A habit with this name already exists.');
    }

    _habits[idx] = updated;
    notifyListeners();

    try {
      await _storage.saveHabit(updated);
      await _notifications.cancelHabitReminder(updated.id);
      if (updated.reminderTime != null && updated.isActive) {
        await _notifications.scheduleHabitReminder(updated);
      }
      await _syncWidget();
    } catch (_) {
      // Avoid blocking UI updates if notification scheduling/storage has issues.
    }
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    _logs.removeWhere((l) => l.habitId == id);
    notifyListeners();

    try {
      await _storage.deleteHabit(id);
      await _notifications.cancelHabitReminder(id);
      await _syncWidget();
    } catch (_) {
      // Continue even if cleanup fails.
    }
  }

  // ── Logging ─────────────────────────────────────────────────────────────────

  /// Returns whether the habit was completed on the given date.
  bool isCompletedOnDate(String habitId, DateTime date) {
    final habit = _habitById(habitId);
    final target = habit?.target ?? 1;
    return _countLogsOnDate(habitId, date) >= target;
  }

  /// Toggle today's completion for a habit.
  Future<void> toggleToday(String habitId) async {
    await toggleForDate(habitId, DateTime.now());
  }

  /// Toggle completion for a specific date.
  Future<void> toggleForDate(String habitId, DateTime date) async {
    final habit = _habitById(habitId);
    if (habit == null) return;

    if (habit.loggingMode == 'check') {
      final targetDay = HabitLog.normalizeDate(date);
      final existing = _logsForDate(habitId, targetDay);

      if (existing.isNotEmpty) {
        for (final log in existing) {
          _logs.removeWhere((entry) => entry.id == log.id);
          _removeLogFromIndexes(log);
          await _storage.deleteLog(log.id);
        }
      } else {
        final log = HabitLog(
          id: _uuid.v4(),
          habitId: habitId,
          date: targetDay,
          loggedAt: date,
          status: 'done',
        );
        _logs.add(log);
        _indexLog(log);
        await _storage.saveLog(log);

        // If 'check' mode target is always 1
        await _notifications.showLocalNotification(
          title: 'Goal Reached! 🎯',
          body: 'You completed your goal for "${habit.title}" today!',
          type: 'habit.completion',
          payload: {'habitId': habitId},
        );
      }
      await _recalcStreak(habitId);
      await _syncWidget();
      notifyListeners();
      return;
    }

    await addOccurrence(habitId, at: date);
  }

  Future<void> addOccurrence(String habitId, {DateTime? at}) async {
    final habit = _habitById(habitId);
    if (habit == null) return;

    final loggedAt = at ?? DateTime.now();
    final log = HabitLog(
      id: _uuid.v4(),
      habitId: habitId,
      date: HabitLog.normalizeDate(loggedAt),
      loggedAt: loggedAt,
      status: 'done',
    );
    _logs.add(log);
    _indexLog(log);
    await _storage.saveLog(log);

    // Notify if milestone reached (completion of daily target)
    final countToday = _countLogsOnDate(habitId, loggedAt);
    if (countToday == habit.target) {
      await _notifications.showLocalNotification(
        title: 'Goal Reached! 🎯',
        body: 'You completed your goal for "${habit.title}" today!',
        type: 'habit.completion',
        payload: {'habitId': habitId},
      );
    }

    await _recalcStreak(habitId);
    await _syncWidget();
    notifyListeners();
  }

  Future<void> removeLatestOccurrence(String habitId, {DateTime? onDate}) async {
    final targetDate = onDate ?? DateTime.now();
    final existing = _logsForDate(habitId, targetDate);
    if (existing.isEmpty) return;

    final log = existing.first;
    _logs.removeWhere((entry) => entry.id == log.id);
    _removeLogFromIndexes(log);
    await _storage.deleteLog(log.id);
    await _recalcStreak(habitId);
    await _syncWidget();
    notifyListeners();
  }

  Future<void> addTimedOccurrence(String habitId, TimeOfDay time) async {
    final now = DateTime.now();
    final loggedAt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    await addOccurrence(habitId, at: loggedAt);
  }

  /// Recompute the streak for a habit from scratch based on logs.
  Future<void> _recalcStreak(String habitId) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;

    final doneDates = _doneDatesForHabit(habitId);

    if (doneDates.isEmpty) {
      final updated = _habits[idx].copyWith(
        currentStreak: 0,
        lastCompletedDate: null,
      );
      _habits[idx] = updated;
      await _storage.saveHabit(updated);
      return;
    }

    final lastDate = doneDates.last;
    final streak = _calculateCurrentStreak(doneDates);
    final longest = _habits[idx].longestStreak;
    final isNewLongest = streak > longest;
    
    final updated = _habits[idx].copyWith(
      currentStreak: streak,
      longestStreak: isNewLongest ? streak : longest,
      lastCompletedDate: lastDate,
    );
    _habits[idx] = updated;
    await _storage.saveHabit(updated);

    if (isNewLongest && streak > 1) {
      await _notifications.showLocalNotification(
        title: 'New Personal Best! 🔥',
        body: 'You reached a $streak day streak for "${updated.title}"!',
        type: 'streak.milestone',
        payload: {'habitId': habitId, 'streak': streak},
      );
    }
  }

  /// Manually trigger a system notification (e.g., from UI button).
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? payload,
  }) async {
    await _notifications.showLocalNotification(
      title: title,
      body: body,
      type: type,
      payload: payload,
    );
  }

  /// On app launch, reset streaks for habits that were missed yesterday.
  void _checkAndResetStreaks() {
    for (int i = 0; i < _habits.length; i++) {
      final h = _habits[i];
      final doneDates = _doneDatesForHabit(h.id);
      final recalculatedStreak = _calculateCurrentStreak(doneDates);
      final lastCompletedDate = doneDates.isEmpty ? null : doneDates.last;

      if (h.currentStreak != recalculatedStreak ||
          h.lastCompletedDate != lastCompletedDate) {
        final updated = h.copyWith(
          currentStreak: recalculatedStreak,
          lastCompletedDate: lastCompletedDate,
        );
        _habits[i] = updated;
        _storage.saveHabit(updated);
      }
    }
  }

  // ── Queries ─────────────────────────────────────────────────────────────────

  int countForDate(String habitId, DateTime date) {
    return _countLogsOnDate(habitId, date);
  }

  List<HabitLog> logsForDate(DateTime date) {
    final normalized = HabitLog.normalizeDate(date);
    return _logs
        .where((log) => HabitLog.normalizeDate(log.loggedAt) == normalized)
        .toList();
  }

  List<HabitLog> logsForHabit(String habitId) {
    return _logs.where((l) => l.habitId == habitId).toList();
  }

  /// Completions this week (Mon-Sun) for a weekly habit.
  int completionsThisWeek(String habitId) {
    final now = DateTime.now();
    final startOfWeek = HabitLog.normalizeDate(
      now.subtract(Duration(days: now.weekday - 1)),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _logs
        .where((l) =>
            l.habitId == habitId &&
            l.status == 'done' &&
        !HabitLog.normalizeDate(l.loggedAt).isBefore(startOfWeek) &&
        !HabitLog.normalizeDate(l.loggedAt).isAfter(endOfWeek))
        .length;
  }

  /// Overall completion rate (last 30 days) across all daily habits.
  double get overallCompletionRate {
    final dailyHabits = activeHabits.where((h) => h.frequency == 'daily');
    if (dailyHabits.isEmpty) return 0.0;

    final today = HabitLog.normalizeDate(DateTime.now());
    int totalExpected = 0;
    int totalDone = 0;

    for (final h in dailyHabits) {
      for (int d = 0; d < 30; d++) {
        final day = today.subtract(Duration(days: d));
        if (!day.isBefore(HabitLog.normalizeDate(h.startDate))) {
          totalExpected++;
          if (isCompletedOnDate(h.id, day)) totalDone++;
        }
      }
    }

    if (totalExpected == 0) return 0.0;
    return totalDone / totalExpected;
  }

  /// Daily completion counts for the last [days] days.
  List<int> dailyCompletionCounts(int days) {
    final today = HabitLog.normalizeDate(DateTime.now());
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      return logsForDate(day).where((l) => l.status == 'done').length;
    });
  }

  /// Habit with the highest current streak.
  Habit? get topStreakHabit {
    if (_habits.isEmpty) return null;
    return _habits.reduce(
      (a, b) => a.currentStreak >= b.currentStreak ? a : b,
    );
  }
}
