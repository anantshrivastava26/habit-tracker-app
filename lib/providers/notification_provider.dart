import 'package:flutter/material.dart';
import '../models/notification_entry.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  List<NotificationEntry> _notifications = [];
  int _unreadCount = 0;

  NotificationProvider(this._repository);

  List<NotificationEntry> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;

  void _recountUnread() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void load() {
    _notifications = _repository.getAll();
    _recountUnread();
    notifyListeners();
  }

  Future<void> addNotification(NotificationEntry entry) async {
    _notifications.insert(0, entry);
    if (!entry.isRead) {
      _unreadCount++;
    }
    notifyListeners();
    await _repository.save(entry);
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      notifyListeners();
      await _repository.markAsRead(id);
    }
  }

  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
    await _repository.markAllAsRead();
  }

  Future<void> deleteNotification(String id) async {
    NotificationEntry? removed;
    for (final entry in _notifications) {
      if (entry.id == id) {
        removed = entry;
        break;
      }
    }
    await _repository.delete(id);
    _notifications.removeWhere((n) => n.id == id);
    if (removed != null && !removed.isRead) {
      _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    _notifications.clear();
    notifyListeners();
  }
}
