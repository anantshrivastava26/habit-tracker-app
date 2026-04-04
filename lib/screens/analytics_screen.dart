import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../providers/habit_provider.dart';
import '../widgets/neu_box.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.activeHabits;
    final completionRate = provider.overallCompletionRate;
    final topHabit = provider.topStreakHabit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: NeuColors.textPrimary(isDark)),
        ),
      ),
      body: habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NeuBox(
                    style: NeuStyle.raised,
                    borderRadius: 28,
                    depth: 8,
                    width: 100,
                    height: 100,
                    child: Icon(
                      Icons.bar_chart_rounded,
                      size: 48,
                      color: NeuColors.textSecondary(isDark)
                          .withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No data yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: NeuColors.textPrimary(isDark)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add habits and start tracking to see stats',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: NeuColors.textSecondary(isDark)),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Summary cards ────────────────────────────────────────
                Row(
                  children: [
                    _SummaryCard(
                      title: 'Completion Rate',
                      value:
                          '${(completionRate * 100).round()}%',
                      icon: Icons.track_changes_rounded,
                      subtitle: 'Last 30 days',
                      color: NeuColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      title: 'Best Streak',
                      value: topHabit != null
                          ? '${topHabit.currentStreak}'
                          : '0',
                      icon: Icons.local_fire_department_rounded,
                      subtitle: topHabit?.title ?? '—',
                      color: const Color(0xFFFF8C00),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SummaryCard(
                      title: 'Total Habits',
                      value: '${habits.length}',
                      icon: Icons.format_list_bulleted_rounded,
                      subtitle: 'Active',
                      color: NeuColors.success,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      title: "Today's Progress",
                      value:
                          '${habits.where((h) => provider.isCompletedOnDate(h.id, DateTime.now())).length}/${habits.length}',
                      icon: Icons.wb_sunny_rounded,
                      subtitle: 'Completed',
                      color: const Color(0xFF2196F3),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Charts ───────────────────────────────────────────────
                _ChartCard(
                  title: 'Last 7 Days',
                  child: _WeekBarChart(provider: provider),
                ),
                const SizedBox(height: 16),
                _ChartCard(
                  title: 'Activity Heatmap (4 weeks)',
                  child: _Heatmap(provider: provider),
                ),
                const SizedBox(height: 20),

                // ── Habit breakdown ──────────────────────────────────────
                Text(
                  'Habit Breakdown',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: NeuColors.textPrimary(isDark)),
                ),
                const SizedBox(height: 12),
                ...habits.map((h) =>
                    _HabitStatRow(habit: h, provider: provider)),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String subtitle;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: NeuBox(
        style: NeuStyle.raised,
        borderRadius: 18,
        depth: 5,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeuBox(
              style: NeuStyle.pressed,
              borderRadius: 12,
              depth: 3,
              width: 40,
              height: 40,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(
              title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: NeuColors.textPrimary(isDark)),
            ),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: NeuColors.textSecondary(isDark)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart Card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return NeuBox(
      style: NeuStyle.raised,
      borderRadius: 18,
      depth: 5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: NeuColors.textPrimary(isDark)),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── 7-Day Bar Chart ───────────────────────────────────────────────────────────

class _WeekBarChart extends StatelessWidget {
  final HabitProvider provider;
  const _WeekBarChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counts = provider.dailyCompletionCounts(7);
    final maxY =
        (counts.reduce((a, b) => a > b ? a : b) + 1).toDouble();
    final today = HabitLog.normalizeDate(DateTime.now());
    final days = List.generate(
        7,
        (i) => DateFormat('E')
            .format(today.subtract(Duration(days: 6 - i))));

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY < 1 ? 1 : maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  days[v.toInt()],
                  style: TextStyle(
                      fontSize: 11,
                      color: NeuColors.textSecondary(isDark)),
                ),
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final isToday = i == 6;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: counts[i].toDouble(),
                  color: isToday
                      ? NeuColors.primary
                      : NeuColors.primary.withOpacity(0.35),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Heatmap ───────────────────────────────────────────────────────────────────

class _Heatmap extends StatelessWidget {
  final HabitProvider provider;
  const _Heatmap({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = HabitLog.normalizeDate(DateTime.now());
    final startOfWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final gridStart =
        startOfWeek.subtract(const Duration(days: 21));
    final maxHabits = provider.activeHabits.length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => SizedBox(
                    width: 32,
                    child: Text(
                      d,
                      style: TextStyle(
                          fontSize: 11,
                          color: NeuColors.textSecondary(isDark)),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(4, (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (day) {
                final date =
                    gridStart.add(Duration(days: week * 7 + day));
                final count = provider
                    .logsForDate(date)
                    .where((l) => l.status == 'done')
                    .length;
                final intensity =
                    maxHabits > 0 ? count / maxHabits : 0.0;
                final isFuture = date.isAfter(today);
                final isToday = _sameDay(date, today);

                return NeuBox(
                  style: count > 0
                      ? NeuStyle.pressed
                      : NeuStyle.raised,
                  borderRadius: 8,
                  depth: 3,
                  width: 32,
                  height: 32,
                  color: isFuture
                      ? null
                      : count > 0
                          ? NeuColors.primary
                              .withOpacity(0.15 + 0.7 * intensity)
                          : null,
                  child: count > 0
                      ? Center(
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              color: intensity > 0.5
                                  ? Colors.white
                                  : NeuColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : isToday
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: NeuColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Less',
                style: TextStyle(
                    fontSize: 10,
                    color: NeuColors.textSecondary(isDark))),
            const SizedBox(width: 4),
            ...[0.15, 0.35, 0.55, 0.75, 0.95].map((op) => Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: NeuColors.primary.withOpacity(op),
                    borderRadius: BorderRadius.circular(3),
                  ),
                )),
            const SizedBox(width: 4),
            Text('More',
                style: TextStyle(
                    fontSize: 10,
                    color: NeuColors.textSecondary(isDark))),
          ],
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Per-Habit Stats ───────────────────────────────────────────────────────────

class _HabitStatRow extends StatelessWidget {
  final Habit habit;
  final HabitProvider provider;

  const _HabitStatRow({required this.habit, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(habit.colorValue);
    final logs = provider.logsForHabit(habit.id);
    final done = logs.where((l) => l.status == 'done').length;

    final today = HabitLog.normalizeDate(DateTime.now());
    int doneThisWeek = 0;
    for (int d = 0; d < 7; d++) {
      if (provider.isCompletedOnDate(
          habit.id, today.subtract(Duration(days: d)))) {
        doneThisWeek++;
      }
    }
    final weekRate = doneThisWeek / 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeuBox(
        style: NeuStyle.raised,
        borderRadius: 14,
        depth: 4,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            NeuBox(
              style: NeuStyle.pressed,
              borderRadius: 12,
              depth: 3,
              width: 44,
              height: 44,
              child: Icon(
                IconData(habit.icon, fontFamily: 'MaterialIcons'),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: NeuColors.textPrimary(isDark)),
                  ),
                  const SizedBox(height: 7),
                  NeuBox(
                    style: NeuStyle.pressed,
                    borderRadius: 4,
                    depth: 2,
                    height: 6,
                    child: FractionallySizedBox(
                      widthFactor: weekRate.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 14, color: Color(0xFFFF8C00)),
                    const SizedBox(width: 2),
                    Text(
                      '${habit.currentStreak}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  '$done total',
                  style: TextStyle(
                      fontSize: 11,
                      color: NeuColors.textSecondary(isDark)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
