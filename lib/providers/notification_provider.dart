import 'package:flutter/material.dart';
import '../models/notification_entry.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  List<NotificationEntry> _notifications = [];

  NotificationProvider(this._repository);

  List<NotificationEntry> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void load() {
    _notifications = _repository.getAll();
    notifyListeners();
  }

  Future<void> addNotification(NotificationEntry entry) async {
    await _repository.save(entry);
    _notifications.insert(0, entry);
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.delete(id);
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    _notifications.clear();
    notifyListeners();
  }
}
