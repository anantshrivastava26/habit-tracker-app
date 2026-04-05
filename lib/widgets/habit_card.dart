import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'neu_box.dart';
import 'streak_badge.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const HabitCard({super.key, required this.habit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final color = Color(habit.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWeekly = habit.frequency == 'weekly';
    final todayCount = provider.countForDate(habit.id, DateTime.now());
    final isCountBased = habit.frequency == 'daily' && habit.target > 1;
    final isCompleted = isCountBased
        ? todayCount >= habit.target
        : provider.isCompletedOnDate(habit.id, DateTime.now());
    final weeklyDone = isWeekly ? provider.completionsThisWeek(habit.id) : 0;
    final weeklyTarget = habit.target;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: NeuBox(
          style: NeuStyle.raised,
          borderRadius: 18,
          depth: 5,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon in neumorphic concave circle
              NeuBox(
                style: isCompleted ? NeuStyle.pressed : NeuStyle.raised,
                borderRadius: 14,
                depth: 4,
                width: 50,
                height: 50,
                child: Icon(
                  IconData(habit.icon, fontFamily: 'MaterialIcons'),
                  color: isCompleted
                      ? color
                      : color.withValues(alpha: 0.75),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            habit.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isCompleted
                                  ? NeuColors.textSecondary(isDark)
                                  : NeuColors.textPrimary(isDark),
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor:
                                  NeuColors.textSecondary(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (habit.currentStreak > 0)
                          StreakBadge(
                              streak: habit.currentStreak, compact: true),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _CategoryChip(
                            category: habit.category, color: color),
                        const SizedBox(width: 6),
                        if (isWeekly)
                          Text(
                            '$weeklyDone/$weeklyTarget this week',
                            style: TextStyle(
                              fontSize: 11,
                              color: NeuColors.textSecondary(isDark),
                            ),
                          ),
                        if (isCountBased)
                          Text(
                            '$todayCount/${habit.target} today',
                            style: TextStyle(
                              fontSize: 11,
                              color: NeuColors.textSecondary(isDark),
                            ),
                          ),
                      ],
                    ),
                    if (isWeekly) ...[
                      const SizedBox(height: 8),
                      _NeuProgressBar(
                        value: weeklyTarget > 0
                            ? weeklyDone / weeklyTarget
                            : 0,
                        color: color,
                      ),
                    ],
                    if (isCountBased) ...[
                      const SizedBox(height: 8),
                      _NeuProgressBar(
                        value: habit.target > 0
                            ? todayCount / habit.target
                            : 0,
                        color: color,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Complete button
              _CompleteButton(
                isCompleted: isCompleted,
                color: color,
                onTap: () {
                  if (isCountBased) {
                    _showCountDialog(context, habit, todayCount);
                  } else {
                    context.read<HabitProvider>().toggleToday(habit.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountDialog(BuildContext context, Habit habit, int currentCount) {
    final controller = TextEditingController(text: '$currentCount');
    showDialog(
      context: context,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text('Log today'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter how many times you did this today.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Target: ${habit.target}',
                style: TextStyle(color: NeuColors.textSecondary(isDark)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final input = int.tryParse(controller.text.trim()) ?? 0;
                context
                    .read<HabitProvider>()
                    .setCountForDate(habit.id, DateTime.now(), input);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _NeuProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _NeuProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return NeuBox(
      style: NeuStyle.pressed,
      borderRadius: 6,
      depth: 3,
      height: 8,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final Color color;

  const _CategoryChip({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final bool isCompleted;
  final Color color;
  final VoidCallback onTap;

  const _CompleteButton({
    required this.isCompleted,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: NeuBox(
        style: isCompleted ? NeuStyle.pressed : NeuStyle.raised,
        borderRadius: 14,
        depth: 4,
        width: 44,
        height: 44,
        child: Icon(
          Icons.check_rounded,
          color: isCompleted
              ? color
              : NeuColors.textSecondary(isDark)
                  .withValues(alpha: 0.3),
          size: 22,
        ),
      ),
    );
  }
}
