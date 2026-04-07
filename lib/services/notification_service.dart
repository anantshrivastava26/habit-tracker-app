import 'package:flutter/services.dart';
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
  static const _systemChannel = MethodChannel('com.lifeloop.app/system');

  static const AndroidNotificationChannel _habitRemindersChannel =
      AndroidNotificationChannel(
    'habit_reminders_v2',
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

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create / update the notification channel every time so it persists across
    // app updates and survives the user deleting it from system settings.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_habitRemindersChannel);

    // Request POST_NOTIFICATIONS permission (Android 13+; no-op on lower APIs).
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    // Request SCHEDULE_EXACT_ALARM permission (Android 12+; no-op on lower APIs).
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (_) {}

    _initialized = true;
  }

  // ── Battery optimisation (critical for Realme / OPPO / Xiaomi devices) ──────

  /// Returns true when this app is already excluded from battery optimisation.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      return await _systemChannel
              .invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system dialog asking the user to exempt this app from battery
  /// optimisation.  Must be called while the activity is in the foreground
  /// (e.g. from a button tap in the Settings screen).
  Future<void> requestBatteryOptimizationExemption() async {
    try {
      await _systemChannel
          .invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  // ── Scheduling ───────────────────────────────────────────────────────────────

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
      playSound: true,
      // Ensure the notification heads-up on locked screen (important for OEM ROMs).
      fullScreenIntent: false,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(sound: _iosSoundName);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        _notifId(habit.id),
        'Time for: ${habit.title}',
        habit.description.isNotEmpty
            ? habit.description
            : 'Keep the streak alive! 🔥',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Fallback for devices that deny exact alarms (e.g. Android 12+ without
      // SCHEDULE_EXACT_ALARM permission granted by the user).
      try {
        await _plugin.zonedSchedule(
          _notifId(habit.id),
          'Time for: ${habit.title}',
          habit.description.isNotEmpty
              ? habit.description
              : 'Keep the streak alive! 🔥',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // Device does not support scheduled notifications; silently ignore.
      }
    }
  }

  Future<void> cancelHabitReminder(String habitId) async {
    await _plugin.cancel(_notifId(habitId));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
