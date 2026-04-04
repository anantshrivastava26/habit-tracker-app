import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/neu_box.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.activeHabits;
    final todayStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = NeuColors.background(isDark);
    final dk = NeuColors.shadowDark(isDark);
    final lt = NeuColors.shadowLight(isDark);

    final todayDone = habits
        .where((h) => provider.isCompletedOnDate(h.id, DateTime.now()))
        .length;

    return Scaffold(
      body: Column(
        children: [
          // ── Neumorphic Header ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                    color: dk,
                    offset: const Offset(4, 8),
                    blurRadius: 16),
                BoxShadow(
                    color: lt,
                    offset: const Offset(-4, -4),
                    blurRadius: 12),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: TextStyle(
                                  color: NeuColors.textSecondary(isDark),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                todayStr,
                                style: TextStyle(
                                  color: NeuColors.textPrimary(isDark),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        NeuButton(
                          onTap: () => showSearch(
                            context: context,
                            delegate: _HabitSearch(habits: habits),
                          ),
                          borderRadius: 12,
                          padding: const EdgeInsets.all(10),
                          depth: 4,
                          child: Icon(Icons.search_rounded,
                              color: NeuColors.primary, size: 22),
                        ),
                      ],
                    ),
                    if (habits.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Habits",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: NeuColors.textSecondary(isDark),
                            ),
                          ),
                          Text(
                            '$todayDone / ${habits.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: NeuColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _NeuProgressBar(
                          done: todayDone, total: habits.length),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Habit List ───────────────────────────────────────────────────
          Expanded(
            child: habits.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 100),
                    itemCount: habits.length,
                    itemBuilder: (ctx, i) => HabitCard(
                      habit: habits[i],
                      onTap: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              HabitDetailScreen(habitId: habits[i].id),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _NeuFab(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHabitScreen()),
        ),
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────

class _NeuProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const _NeuProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? done / total : 0.0;
    return NeuBox(
      style: NeuStyle.pressed,
      borderRadius: 8,
      depth: 3,
      height: 10,
      child: FractionallySizedBox(
        widthFactor: pct.clamp(0.0, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9C88FF)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeuBox(
            style: NeuStyle.raised,
            borderRadius: 28,
            depth: 8,
            width: 100,
            height: 100,
            child: Icon(Icons.spa_outlined,
                size: 48,
                color: NeuColors.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No habits yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: NeuColors.textPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first habit',
            style: TextStyle(color: NeuColors.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _NeuFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NeuFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NeuButton(
      onTap: onTap,
      borderRadius: 18,
      depth: 6,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, color: NeuColors.primary, size: 22),
          const SizedBox(width: 8),
          const Text(
            'New Habit',
            style: TextStyle(
              color: NeuColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search ────────────────────────────────────────────────────────────────────

class _HabitSearch extends SearchDelegate<String> {
  final List habits;

  _HabitSearch({required this.habits});

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = habits
        .where(
            (h) => h.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => HabitCard(
        habit: results[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HabitDetailScreen(habitId: results[i].id),
          ),
        ),
      ),
    );
  }
}
