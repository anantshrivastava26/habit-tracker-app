import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/habit.dart';
import '../models/notification_entry.dart';
import '../providers/notification_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static const _iosSoundName = 'habit_chime.aiff';
  static const _systemChannel = MethodChannel('com.lifeloop.app/system');

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
  bool _initializing = false;
  NotificationProvider? _notificationProvider;
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> init({
    NotificationProvider? notificationProvider,
    GlobalKey<NavigatorState>? navigatorKey,
  }) async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _notificationProvider = notificationProvider;
    _navigatorKey = navigatorKey;
    try {
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (_) {}

      const android = AndroidInitializationSettings('ic_notification');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_habitRemindersChannel);

      _initialized = true;
      unawaited(_requestAndroidPermissions());
    } finally {
      _initializing = false;
    }
  }

  Future<void> _requestAndroidPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}

    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushNamed('/notifications');
    }
  }

  /// Manually trigger a local notification and save it to the inbox.
  /// This mimics the "Foreground Handling" logic.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? payload,
  }) async {
    final entry = NotificationEntry(
      title: title,
      body: body,
      type: type,
      payload: payload,
    );

    // 1. Save to local inbox via provider
    if (_notificationProvider != null) {
      await _notificationProvider!.addNotification(entry);
    }

    // 2. Show the system notification (Banner/Heads-up)
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
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      entry.id.hashCode.abs(),
      title,
      body,
      details,
      payload: entry.toJson(),
    );
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
      color: const Color(0xFF6200EE),

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
