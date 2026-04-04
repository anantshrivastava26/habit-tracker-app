import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class HabitProvider extends ChangeNotifier {
  final StorageService _storage;
  final NotificationService _notifications;
  static const _uuid = Uuid();

  List<Habit> _habits = [];
  List<HabitLog> _logs = [];

  HabitProvider(this._storage, this._notifications);

  List<Habit> get habits => List.unmodifiable(_habits);
  List<HabitLog> get logs => List.unmodifiable(_logs);

  /// Active habits only
  List<Habit> get activeHabits => _habits.where((h) => h.isActive).toList();

  void load() {
    _habits = _storage.loadHabits();
    _logs = _storage.loadLogs();
    // On load, check if any streaks need resetting due to missed days
    _checkAndResetStreaks();
    notifyListeners();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> addHabit(Habit habit) async {
    final h = habit.copyWith(id: habit.id.isEmpty ? _uuid.v4() : habit.id);
    _habits.add(h);
    notifyListeners();

    try {
      await _storage.saveHabit(h);
      if (h.reminderTime != null) {
        await _notifications.scheduleHabitReminder(h);
      }
    } catch (_) {
      // Keep the UI responsive even if storage or scheduling fails.
    }
  }

  Future<void> updateHabit(Habit updated) async {
    final idx = _habits.indexWhere((h) => h.id == updated.id);
    if (idx == -1) return;
    _habits[idx] = updated;
    notifyListeners();

    try {
      await _storage.saveHabit(updated);
      await _notifications.cancelHabitReminder(updated.id);
      if (updated.reminderTime != null && updated.isActive) {
        await _notifications.scheduleHabitReminder(updated);
      }
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
    } catch (_) {
      // Continue even if cleanup fails.
    }
  }

  // ── Logging ─────────────────────────────────────────────────────────────────

  /// Returns whether the habit was completed on the given date.
  bool isCompletedOnDate(String habitId, DateTime date) {
    final normalized = HabitLog.normalizeDate(date);
    return _logs.any(
      (l) => l.habitId == habitId && l.date == normalized && l.status == 'done',
    );
  }

  /// Toggle today's completion for a habit.
  Future<void> toggleToday(String habitId) async {
    final today = HabitLog.normalizeDate(DateTime.now());

    final existing = _logs.where(
      (l) => l.habitId == habitId && l.date == today,
    ).toList();

    if (existing.isNotEmpty) {
      // Un-complete: remove today's log
      for (final log in existing) {
        _logs.removeWhere((l) => l.id == log.id);
        await _storage.deleteLog(log.id);
      }
      await _recalcStreak(habitId);
    } else {
      // Mark complete
      final log = HabitLog(
        id: _uuid.v4(),
        habitId: habitId,
        date: today,
        status: 'done',
      );
      _logs.add(log);
      await _storage.saveLog(log);
      await _markComplete(habitId, today);
    }
    notifyListeners();
  }

  Future<void> _markComplete(String habitId, DateTime date) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;
    final habit = _habits[idx];
    final normalized = HabitLog.normalizeDate(date);

    int newStreak = habit.currentStreak;
    final last = habit.lastCompletedDate;

    if (last == null) {
      newStreak = 1;
    } else {
      final diff = normalized.difference(last).inDays;
      if (diff == 0) return; // already counted
      if (diff == 1) {
        newStreak = habit.currentStreak + 1;
      } else {
        newStreak = 1; // streak broken
      }
    }

    final updated = habit.copyWith(
      currentStreak: newStreak,
      longestStreak:
          newStreak > habit.longestStreak ? newStreak : habit.longestStreak,
      lastCompletedDate: normalized,
    );
    _habits[idx] = updated;
    await _storage.saveHabit(updated);
  }

  /// Recompute the streak for a habit from scratch based on logs.
  Future<void> _recalcStreak(String habitId) async {
    final idx = _habits.indexWhere((h) => h.id == habitId);
    if (idx == -1) return;

    final doneDates = _logs
        .where((l) => l.habitId == habitId && l.status == 'done')
        .map((l) => l.date)
        .toSet()
        .toList()
      ..sort();

    if (doneDates.isEmpty) {
      final updated = _habits[idx].copyWith(
        currentStreak: 0,
        lastCompletedDate: null,
      );
      _habits[idx] = updated;
      await _storage.saveHabit(updated);
      return;
    }

    // Calculate current streak from today backwards
    final today = HabitLog.normalizeDate(DateTime.now());
    int streak = 0;
    DateTime cursor = today;

    while (doneDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    final lastDate = doneDates.last;
    final longest = _habits[idx].longestStreak;
    final updated = _habits[idx].copyWith(
      currentStreak: streak,
      longestStreak: streak > longest ? streak : longest,
      lastCompletedDate: lastDate,
    );
    _habits[idx] = updated;
    await _storage.saveHabit(updated);
  }

  /// On app launch, reset streaks for habits that were missed yesterday.
  void _checkAndResetStreaks() {
    final today = HabitLog.normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    for (int i = 0; i < _habits.length; i++) {
      final h = _habits[i];
      if (!h.isActive || h.currentStreak == 0) continue;
      final last = h.lastCompletedDate;
      if (last == null) continue;

      // If last completion was before yesterday, streak is broken
      if (last.isBefore(yesterday)) {
        _habits[i] = h.copyWith(currentStreak: 0);
        _storage.saveHabit(_habits[i]);
      }
    }
  }

  // ── Queries ─────────────────────────────────────────────────────────────────

  List<HabitLog> logsForDate(DateTime date) {
    final normalized = HabitLog.normalizeDate(date);
    return _logs.where((l) => l.date == normalized).toList();
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
            !l.date.isBefore(startOfWeek) &&
            !l.date.isAfter(endOfWeek))
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
