import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const AndroidNotificationChannel _habitRemindersChannel =
      AndroidNotificationChannel(
    'habit_reminders',
    'Habit Reminders',
    description: 'Daily reminders for your habits',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_habitRemindersChannel);

    // Safe across Android versions: this only prompts on Android 13+.
    try {
      await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    } catch (_) {
      // Avoid startup crashes if a device/ROM throws here.
    }

    _initialized = true;
  }

  int _notifId(String habitId) => habitId.hashCode.abs() % 2147483647;

  Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null || !habit.isActive) return;

    final parts = habit.reminderTime!.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _habitRemindersChannel.id,
      _habitRemindersChannel.name,
      channelDescription: _habitRemindersChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _plugin.zonedSchedule(
        _notifId(habit.id),
        '${habit.icon} Time for: ${habit.title}',
        habit.description.isNotEmpty
            ? habit.description
            : 'Keep the streak alive! 🔥',
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback for devices where exact scheduling isn't available.
      await _plugin.zonedSchedule(
        _notifId(habit.id),
        '${habit.icon} Time for: ${habit.title}',
        habit.description.isNotEmpty
            ? habit.description
            : 'Keep the streak alive! 🔥',
        scheduledDate,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await _plugin.cancel(_notifId(habitId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
