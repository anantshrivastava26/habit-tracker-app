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
    final todayCount = provider.countForDate(habitId, DateTime.now());
    final totalCount = provider.totalCountForHabit(habit.id);
    final logs = provider.logsForHabit(habitId);
    final doneLogs = logs.where((l) => l.status == 'done').toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final recentLogs = doneLogs.take(10).toList();

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
                value: '$totalCount',
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
          if (habit.frequency == 'daily' && habit.target > 1) ...[
            NeuBox(
              style: NeuStyle.raised,
              borderRadius: 18,
              depth: 5,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(
                              fontSize: 12,
                              color: NeuColors.textSecondary(isDark)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$todayCount/${habit.target}',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: NeuColors.textPrimary(isDark)),
                        ),
                      ],
                    ),
                  ),
                  NeuButton(
                    onTap: () => _showCountDialog(context, habit, todayCount),
                    borderRadius: 14,
                    depth: 5,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Text(
                      'Update',
                      style: TextStyle(
                          color: NeuColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
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
                  return Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, MMM d')
                                  .format(log.date),
                              style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      NeuColors.textPrimary(isDark)),
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
              const Text('Enter how many times you did this today.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
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
