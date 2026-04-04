import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class StorageService {
  static const _habitsBox = 'habits';
  static const _logsBox = 'habit_logs';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_habitsBox);
    await Hive.openBox<String>(_logsBox);
  }

  // ── Habits ──────────────────────────────────────────────────────────────────

  Box<String> get _habits => Hive.box<String>(_habitsBox);
  Box<String> get _logs => Hive.box<String>(_logsBox);

  Future<void> saveHabit(Habit habit) async {
    await _habits.put(habit.id, habit.toJsonString());
  }

  Future<void> deleteHabit(String id) async {
    await _habits.delete(id);
    // also delete associated logs
    final logKeys = _logs.keys
        .where((k) {
          try {
            final log = HabitLog.fromJsonString(_logs.get(k as String)!);
            return log.habitId == id;
          } catch (_) {
            return false;
          }
        })
        .toList();
    await _logs.deleteAll(logKeys);
  }

  List<Habit> loadHabits() {
    return _habits.values.map((s) {
      try {
        return Habit.fromJsonString(s);
      } catch (_) {
        return null;
      }
    }).whereType<Habit>().toList();
  }

  // ── Logs ────────────────────────────────────────────────────────────────────

  Future<void> saveLog(HabitLog log) async {
    await _logs.put(log.id, log.toJsonString());
  }

  Future<void> deleteLog(String id) async {
    await _logs.delete(id);
  }

  List<HabitLog> loadLogs() {
    return _logs.values.map((s) {
      try {
        return HabitLog.fromJsonString(s);
      } catch (_) {
        return null;
      }
    }).whereType<HabitLog>().toList();
  }

  List<HabitLog> logsForHabit(String habitId) {
    return loadLogs().where((l) => l.habitId == habitId).toList();
  }

  /// Returns logs for a specific normalized date.
  List<HabitLog> logsForDate(DateTime date) {
    final normalized = HabitLog.normalizeDate(date);
    return loadLogs().where((l) => l.date == normalized).toList();
  }
}
