import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const _iosSoundName = 'habit_chime.aiff';

  static const AndroidNotificationChannel _habitRemindersChannel =
      AndroidNotificationChannel(
    'habit_reminders_v3',
    'Habit Reminders',
    description: 'Daily reminders for your habits',
    importance: Importance.high,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // Fall back to the package default location if the platform lookup fails.
    }

    const android = AndroidInitializationSettings('ic_notification');
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

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (_) {
      // Some Android builds do not expose the exact-alarm prompt.
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
      color: const Color(0xFF6200EE),

      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(sound: _iosSoundName);

    try {
      await _plugin.zonedSchedule(
        _notifId(habit.id),
        'Time for: ${habit.title}',
        habit.description.isNotEmpty
            ? habit.description
            : 'Keep the streak alive! 🔥',
        scheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback for devices where exact scheduling isn't available.
      await _plugin.zonedSchedule(
        _notifId(habit.id),
        'Time for: ${habit.title}',
        habit.description.isNotEmpty
            ? habit.description
            : 'Keep the streak alive! 🔥',
        scheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
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
