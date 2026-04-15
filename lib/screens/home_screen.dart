import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/neu_box.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory; // null = show all

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
    final allHabits = provider.activeHabits;
    final todayStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = NeuColors.background(isDark);
    final dk = NeuColors.shadowDark(isDark);
    final lt = NeuColors.shadowLight(isDark);

    // Unique categories present in active habits
    final categories = allHabits.map((h) => h.category).toSet().toList()
      ..sort();

    // Apply category filter
    final habits = _selectedCategory == null
        ? allHabits
        : allHabits.where((h) => h.category == _selectedCategory).toList();

    final todayDone = allHabits
        .where((h) => provider.isCompletedOnDate(h.id, DateTime.now()))
        .length;

    return Scaffold(
      body: Column(
        children: [
          // ── Neumorphic Header ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                    color: dk, offset: const Offset(4, 8), blurRadius: 16),
                BoxShadow(
                    color: lt, offset: const Offset(-4, -4), blurRadius: 12),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting + search + notifications
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
                        _NotificationBadge(isDark: isDark),
                        const SizedBox(width: 12),
                        NeuButton(
                          onTap: () => showSearch(
                            context: context,
                            delegate: _HabitSearch(habits: allHabits),
                          ),
                          borderRadius: 12,
                          padding: const EdgeInsets.all(10),
                          depth: 4,
                          child: Icon(Icons.search_rounded,
                              color: NeuColors.primary, size: 22),
                        ),
                      ],
                    ),

                    if (allHabits.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      // Today's habits count + progress
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
                            '$todayDone / ${allHabits.length}',
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
                          done: todayDone, total: allHabits.length),

                      // ── Category filter chips ──────────────────────────
                      if (categories.length > 1) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 32,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChip(
                                label: 'All',
                                selected: _selectedCategory == null,
                                onTap: () =>
                                    setState(() => _selectedCategory = null),
                                isDark: isDark,
                              ),
                              ...categories.map(
                                (cat) => _FilterChip(
                                  label: cat,
                                  selected: _selectedCategory == cat,
                                  onTap: () => setState(() =>
                                      _selectedCategory =
                                          _selectedCategory == cat
                                              ? null
                                              : cat),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Habit List ─────────────────────────────────────────────────
          Expanded(
            child: habits.isEmpty
                ? (allHabits.isEmpty
                    ? const _EmptyState()
                    : _NoFilterResults(
                        category: _selectedCategory ?? '',
                        isDark: isDark,
                        onClear: () =>
                            setState(() => _selectedCategory = null),
                      ))
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

class _NotificationBadge extends StatelessWidget {
  final bool isDark;

  const _NotificationBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<NotificationProvider, int>(
      (p) => p.unreadCount,
    );

    return Stack(
      children: [
        NeuButton(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          borderRadius: 12,
          padding: const EdgeInsets.all(10),
          depth: 4,
          child: Icon(
            unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_rounded,
            color: unreadCount > 0 ? Colors.orange : NeuColors.textSecondary(isDark),
            size: 22,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Category filter chip ──────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? NeuColors.primary
                : NeuColors.background(isDark),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? NeuColors.primary
                  : NeuColors.textSecondary(isDark).withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: NeuColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Colors.white
                  : NeuColors.textSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty filter result ────────────────────────────────────────────────────────

class _NoFilterResults extends StatelessWidget {
  final String category;
  final bool isDark;
  final VoidCallback onClear;

  const _NoFilterResults({
    required this.category,
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off_rounded,
              size: 48,
              color: NeuColors.textSecondary(isDark).withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No habits in "$category"',
            style: TextStyle(
              fontSize: 15,
              color: NeuColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClear,
            child: const Text('Show all'),
          ),
        ],
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
  final List<Habit> habits;

  _HabitSearch({required this.habits});

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.clear), onPressed: () => query = ''),
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
        .where((h) => h.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => HabitCard(
        habit: results[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HabitDetailScreen(habitId: results[i].id),
          ),
        ),
      ),
    );
  }
}
