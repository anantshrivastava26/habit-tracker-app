import 'dart:convert';
import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String title;
  final String description;
  final String category;
  final String frequency; // 'daily' | 'weekly'
  final String loggingMode; // 'check' | 'count' | 'time'
  final int target;
  final DateTime startDate;
  final String? reminderTime; // "HH:mm"
  final int colorValue;
  final int icon; // Material Icons codePoint
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    this.frequency = 'daily',
    this.loggingMode = 'check',
    this.target = 1,
    required this.startDate,
    this.reminderTime,
    this.colorValue = 0xFF6C63FF,
    int? icon,
    this.isActive = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
  }) : icon = icon ?? Icons.star.codePoint;

  Habit copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? frequency,
    String? loggingMode,
    int? target,
    DateTime? startDate,
    Object? reminderTime = _sentinel,
    int? colorValue,
    int? icon,
    bool? isActive,
    int? currentStreak,
    int? longestStreak,
    Object? lastCompletedDate = _sentinel,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      loggingMode: loggingMode ?? this.loggingMode,
      target: target ?? this.target,
      startDate: startDate ?? this.startDate,
      reminderTime: reminderTime == _sentinel
          ? this.reminderTime
          : reminderTime as String?,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate == _sentinel
          ? this.lastCompletedDate
          : lastCompletedDate as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'frequency': frequency,
        'loggingMode': loggingMode,
        'target': target,
        'startDate': startDate.toIso8601String(),
        'reminderTime': reminderTime,
        'colorValue': colorValue,
        'icon': icon,
        'isActive': isActive,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        frequency: json['frequency'] as String? ?? 'daily',
        loggingMode: json['loggingMode'] as String? ?? 'check',
        target: json['target'] as int? ?? 1,
        startDate: DateTime.parse(json['startDate'] as String),
        reminderTime: json['reminderTime'] as String?,
        colorValue: json['colorValue'] as int? ?? 0xFF6C63FF,
        // Backwards compat: old data stored emoji strings; treat non-int as default
        icon: json['icon'] is int
            ? json['icon'] as int
            : Icons.star.codePoint,
        isActive: json['isActive'] as bool? ?? true,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.parse(json['lastCompletedDate'] as String)
            : null,
      );

  String toJsonString() => jsonEncode(toJson());
  factory Habit.fromJsonString(String s) =>
      Habit.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

const Object _sentinel = Object();

const List<String> kCategories = [
  'General',
  'Health',
  'Fitness',
  'Mind',
  'Work',
  'Personal',
  'Finance',
  'Social',
];

final List<IconData> kIcons = [
  Icons.star,
  Icons.fitness_center,
  Icons.self_improvement,
  Icons.menu_book,
  Icons.water_drop,
  Icons.directions_run,
  Icons.restaurant,
  Icons.bedtime,
  Icons.edit,
  Icons.track_changes,
  Icons.psychology,
  Icons.medication,
  Icons.music_note,
  Icons.eco,
  Icons.wb_sunny,
  Icons.local_fire_department,
  Icons.savings,
  Icons.handshake,
  Icons.cleaning_services,
  Icons.pets,
];
