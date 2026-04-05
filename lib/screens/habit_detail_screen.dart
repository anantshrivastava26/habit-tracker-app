import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';
import '../widgets/streak_badge.dart';
import '../widgets/neu_box.dart';
import 'add_habit_screen.dart';

class HabitDetailScreen extends StatelessWidget {
  final String habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habit =
        provider.habits.where((h) => h.id == habitId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (habit == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Habit not found')),
      );
    }

    final color = Color(habit.colorValue);
    final logs = provider.logsForHabit(habitId);
    final doneLogs = logs.where((l) => l.status == 'done').toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final recentLogs = doneLogs.take(10).toList();
    final todayCount = provider.countForDate(habitId, DateTime.now());
    final periodCount = habit.frequency == 'weekly'
        ? provider.completionsThisWeek(habitId)
        : todayCount;
    final todayDone = provider.isCompletedOnDate(habitId, DateTime.now());
    final periodLabel = habit.frequency == 'weekly' ? 'This week' : 'Today';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          habit.title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: NeuColors.textPrimary(isDark)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          NeuButton(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => AddHabitScreen(editHabit: habit)),
            ),
            borderRadius: 10,
            padding: const EdgeInsets.all(10),
            depth: 4,
            child: Icon(Icons.edit_outlined,
                color: NeuColors.textSecondary(isDark), size: 20),
          ),
          const SizedBox(width: 4),
          NeuButton(
            onTap: () => _confirmDelete(context, provider),
            borderRadius: 10,
            padding: const EdgeInsets.all(10),
            depth: 4,
            child: Icon(Icons.delete_outline_rounded,
                color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header card ────────────────────────────────────────────────
          NeuBox(
            style: NeuStyle.raised,
            borderRadius: 22,
            depth: 6,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                NeuBox(
                  style: NeuStyle.pressed,
                  borderRadius: 22,
                  depth: 5,
                  width: 84,
                  height: 84,
                  child: Icon(
                    IconData(habit.icon, fontFamily: 'MaterialIcons'),
                    color: color,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  habit.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: NeuColors.textPrimary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (habit.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    habit.description,
                    style: TextStyle(
                        color: NeuColors.textSecondary(isDark),
                        fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick Log Controls ────────────────────────────────────────
          NeuBox(
            style: NeuStyle.raised,
            borderRadius: 18,
            depth: 5,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: NeuColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 10),
                if (habit.loggingMode == 'check')
                  SizedBox(
                    width: double.infinity,
                    child: NeuButton(
                      onTap: () => provider.toggleToday(habit.id),
                      borderRadius: 14,
                      depth: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        todayDone ? 'Mark incomplete' : 'Mark complete',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: NeuBox(
                          style: NeuStyle.pressed,
                          borderRadius: 14,
                          depth: 4,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                color: color,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                  '$periodCount / ${habit.target} ${habit.frequency == 'weekly' ? 'this week' : 'today'}',
                                style: TextStyle(
                                  color: NeuColors.textPrimary(isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      NeuButton(
                        onTap: () async {
                          if (habit.loggingMode == 'time') {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked == null || !context.mounted) return;
                            await provider.addTimedOccurrence(habit.id, picked);
                          } else {
                            await provider.addOccurrence(habit.id);
                          }
                        },
                        borderRadius: 14,
                        depth: 4,
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          habit.loggingMode == 'time'
                              ? Icons.schedule_rounded
                              : Icons.add_rounded,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeuButton(
                        onTap: todayCount > 0
                            ? () => provider.removeLatestOccurrence(habit.id)
                            : null,
                        borderRadius: 14,
                        depth: 4,
                        padding: const EdgeInsets.all(14),
                        child: Icon(
                          Icons.remove_rounded,
                          color: todayCount > 0
                              ? Colors.red.shade400
                              : NeuColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Stats row ──────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                label: 'Current\nStreak',
                value: '${habit.currentStreak}',
                unit: 'days',
                icon: Icons.local_fire_department,
                color: const Color(0xFFFF8C00),
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Best\nStreak',
                value: '${habit.longestStreak}',
                unit: 'days',
                icon: Icons.emoji_events_outlined,
                color: const Color(0xFFFFCA28),
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Total\nDone',
                value: '${doneLogs.length}',
                unit: 'times',
                icon: Icons.check_circle_outline_rounded,
                color: NeuColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Streak badge ───────────────────────────────────────────────
          if (habit.currentStreak > 0) ...[
            Center(child: StreakBadge(streak: habit.currentStreak)),
            const SizedBox(height: 20),
          ],

          // ── Details card ───────────────────────────────────────────────
          NeuBox(
            style: NeuStyle.raised,
            borderRadius: 18,
            depth: 5,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.repeat_rounded,
                  label: 'Frequency',
                  value: habit.frequency == 'weekly'
                      ? '${habit.target}x / week'
                      : 'Daily',
                  color: color,
                ),
                _RowDivider(isDark: isDark),
                _DetailRow(
                  icon: Icons.fact_check_outlined,
                  label: 'Logging',
                  value: habit.loggingMode == 'check'
                      ? 'Check-in'
                      : habit.loggingMode == 'count'
                          ? 'Count'
                          : 'Time-based',
                  color: color,
                ),
                _RowDivider(isDark: isDark),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: habit.category,
                  color: color,
                ),
                _RowDivider(isDark: isDark),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Started',
                  value: DateFormat('MMM d, yyyy').format(habit.startDate),
                  color: color,
                ),
                if (habit.reminderTime != null) ...[
                  _RowDivider(isDark: isDark),
                  _DetailRow(
                    icon: Icons.notifications_outlined,
                    label: 'Reminder',
                    value: habit.reminderTime!,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Recent Activity ────────────────────────────────────────────
          Text(
            'Recent Activity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: NeuColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          if (recentLogs.isEmpty)
            Text(
              'No completions yet. Start today!',
              style: TextStyle(color: NeuColors.textSecondary(isDark)),
            )
          else
            NeuBox(
              style: NeuStyle.raised,
              borderRadius: 18,
              depth: 5,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(recentLogs.length, (i) {
                  final log = recentLogs[i];
                  final isLast = i == recentLogs.length - 1;
                  final hasTime =
                      log.loggedAt.hour != 0 || log.loggedAt.minute != 0;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hasTime
                                    ? '${DateFormat('EEEE, MMM d').format(log.loggedAt)} • ${DateFormat('h:mm a').format(log.loggedAt)}'
                                    : DateFormat('EEEE, MMM d')
                                        .format(log.loggedAt),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: NeuColors.textPrimary(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          color: NeuColors.textSecondary(isDark)
                              .withValues(alpha: 0.1),
                          height: 1,
                        ),
                    ],
                  );
                }),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, HabitProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text(
            'This will permanently delete this habit and all its history. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await provider.deleteHabit(habitId);
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final bool isDark;
  const _RowDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
      color: NeuColors.textSecondary(isDark)
          .withValues(alpha: 0.1),
      height: 1);
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: NeuBox(
        style: NeuStyle.raised,
        borderRadius: 16,
        depth: 5,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(unit,
                style: TextStyle(
                    fontSize: 10,
                    color: NeuColors.textSecondary(isDark))),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 9, color: NeuColors.textSecondary(isDark)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          NeuBox(
            style: NeuStyle.raised,
            borderRadius: 10,
            depth: 3,
            width: 36,
            height: 36,
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: NeuColors.textSecondary(isDark), fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: NeuColors.textPrimary(isDark))),
        ],
      ),
    );
  }
}
