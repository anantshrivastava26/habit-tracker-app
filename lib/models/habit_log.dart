import 'dart:convert';

class HabitLog {
  final String id;
  final String habitId;
  final DateTime date; // normalized to midnight local time
  final DateTime loggedAt;
  final String status; // 'done' | 'skipped'
  final String notes;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    DateTime? loggedAt,
    this.status = 'done',
    this.notes = '',
  }) : loggedAt = loggedAt ?? date;

  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'date': date.toIso8601String(),
        'loggedAt': loggedAt.toIso8601String(),
        'status': status,
        'notes': notes,
      };

  factory HabitLog.fromJson(Map<String, dynamic> json) => HabitLog(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        date: DateTime.parse(json['date'] as String),
        loggedAt: json['loggedAt'] != null
            ? DateTime.parse(json['loggedAt'] as String)
            : DateTime.parse(json['date'] as String),
        status: json['status'] as String? ?? 'done',
        notes: json['notes'] as String? ?? '',
      );

  String toJsonString() => jsonEncode(toJson());
  factory HabitLog.fromJsonString(String s) =>
      HabitLog.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
