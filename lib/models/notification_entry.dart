import 'dart:convert';
import 'package:uuid/uuid.dart';

class NotificationEntry {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? type; // e.g., 'habit.reminder', 'streak.milestone', 'system'
  final Map<String, dynamic>? payload;
  final bool isRead;

  NotificationEntry({
    String? id,
    required this.title,
    required this.body,
    DateTime? timestamp,
    this.type,
    this.payload,
    this.isRead = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  NotificationEntry copyWith({
    String? title,
    String? body,
    bool? isRead,
  }) {
    return NotificationEntry(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp,
      type: type,
      payload: payload,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'payload': payload,
      'isRead': isRead,
    };
  }

  factory NotificationEntry.fromMap(Map<String, dynamic> map) {
    return NotificationEntry(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      payload: map['payload'] != null ? Map<String, dynamic>.from(map['payload']) : null,
      isRead: map['isRead'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationEntry.fromJson(String source) =>
      NotificationEntry.fromMap(json.decode(source));
}
