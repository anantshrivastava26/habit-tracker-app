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
    final isCompleted = provider.isCompletedOnDate(habit.id, DateTime.now());
    final color = Color(habit.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayCount = provider.countForDate(habit.id, DateTime.now());

    final isWeekly = habit.frequency == 'weekly';
    final weeklyDone = isWeekly ? provider.completionsThisWeek(habit.id) : 0;
    final weeklyTarget = habit.target;
    final usesCountControls = habit.loggingMode != 'check';
    final displayCount = isWeekly ? weeklyDone : todayCount;
    final countLabel = isWeekly ? 'this week' : 'today';

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
                        if (usesCountControls && !isWeekly)
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (usesCountControls)
                _OccurrenceControls(
                  count: displayCount,
                  target: habit.target,
                  label: countLabel,
                  color: color,
                  isDark: isDark,
                  onIncrement: () async {
                    if (habit.loggingMode == 'time') {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked == null || !context.mounted) return;
                      await context
                          .read<HabitProvider>()
                          .addTimedOccurrence(habit.id, picked);
                      return;
                    }
                    await context.read<HabitProvider>().addOccurrence(habit.id);
                  },
                  onDecrement: () => context
                      .read<HabitProvider>()
                      .removeLatestOccurrence(habit.id),
                )
              else
                _CompleteButton(
                  isCompleted: isCompleted,
                  color: color,
                  onTap: () =>
                      context.read<HabitProvider>().toggleToday(habit.id),
                ),
            ],
          ),
        ),
      ),
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

class _OccurrenceControls extends StatelessWidget {
  final int count;
  final int target;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _OccurrenceControls({
    required this.count,
    required this.target,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = count >= target;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeuBox(
          style: isComplete ? NeuStyle.pressed : NeuStyle.raised,
          borderRadius: 14,
          depth: 4,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            children: [
              Text(
                '$count/$target',
                style: TextStyle(
                  color: isComplete ? color : NeuColors.textPrimary(isDark),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: NeuColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuButton(
              onTap: count > 0 ? onDecrement : null,
              borderRadius: 10,
              padding: const EdgeInsets.all(8),
              depth: 3,
              child: Icon(
                Icons.remove_rounded,
                size: 18,
                color: count > 0
                    ? Colors.red.shade400
                    : NeuColors.textSecondary(isDark),
              ),
            ),
            const SizedBox(width: 8),
            NeuButton(
              onTap: onIncrement,
              borderRadius: 10,
              padding: const EdgeInsets.all(8),
              depth: 3,
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
