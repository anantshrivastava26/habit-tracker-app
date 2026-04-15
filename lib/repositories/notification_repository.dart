import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_entry.dart';

class NotificationRepository {
  static const _boxName = 'notification_inbox';

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<void> save(NotificationEntry notification) async {
    await _box.put(notification.id, notification.toJson());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> markAsRead(String id) async {
    final json = _box.get(id);
    if (json != null) {
      final notification = NotificationEntry.fromJson(json);
      await save(notification.copyWith(isRead: true));
    }
  }

  Future<void> markAllAsRead() async {
    for (var key in _box.keys) {
      final json = _box.get(key);
      if (json != null) {
        final notification = NotificationEntry.fromJson(json);
        if (!notification.isRead) {
          await save(notification.copyWith(isRead: true));
        }
      }
    }
  }

  List<NotificationEntry> getAll() {
    final list = _box.values.map((s) => NotificationEntry.fromJson(s)).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
