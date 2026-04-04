import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/habit_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'app_theme.dart';
import 'widgets/neu_box.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await StorageService.init();

  final notifications = NotificationService();
  await notifications.init();

  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(
          create: (_) {
            final provider = HabitProvider(storage, notifications);
            provider.load();
            return provider;
          },
        ),
      ],
      child: const HabitTrackerApp(),
    ),
  );
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    CalendarScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _NeuNavBar(
        selectedIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Neumorphic Bottom Nav ─────────────────────────────────────────────────────

class _NeuNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _NeuNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Today'),
    (
      icon: Icons.calendar_month_outlined,
      active: Icons.calendar_month,
      label: 'Calendar'
    ),
    (
      icon: Icons.bar_chart_outlined,
      active: Icons.bar_chart_rounded,
      label: 'Analytics'
    ),
    (
      icon: Icons.settings_outlined,
      active: Icons.settings_rounded,
      label: 'Settings'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = NeuColors.background(isDark);
    final dk = NeuColors.shadowDark(isDark);
    final lt = NeuColors.shadowLight(isDark);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(color: dk, offset: const Offset(0, -4), blurRadius: 12),
          BoxShadow(color: lt, offset: const Offset(0, 2), blurRadius: 8),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final isSelected = i == selectedIndex;
              return _NavItem(
                icon: isSelected ? _items[i].active : _items[i].icon,
                label: _items[i].label,
                isSelected: isSelected,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected
        ? NeuColors.primary
        : NeuColors.textSecondary(isDark);

    return GestureDetector(
      onTap: onTap,
      child: NeuBox(
        style: isSelected ? NeuStyle.pressed : NeuStyle.raised,
        borderRadius: 14,
        depth: 4,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
