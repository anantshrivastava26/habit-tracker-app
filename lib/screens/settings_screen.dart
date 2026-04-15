import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/habit_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch to dark theme'),
            secondary: const Icon(Icons.dark_mode),
            value: settings.darkMode,
            activeThumbColor: const Color(0xFF6C63FF),
            onChanged: settings.setDarkMode,
          ),

          const _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Scheduled Reminders'),
            subtitle: const Text('Receive habit reminders'),
            secondary: const Icon(Icons.notifications),
            value: settings.reminderNotificationsEnabled,
            activeThumbColor: const Color(0xFF6C63FF),
            onChanged: (v) async {
              await settings.setReminderNotificationsEnabled(v);
              if (!context.mounted) return;
              await context.read<HabitProvider>().syncReminderSchedules();
            },
          ),
          SwitchListTile(
            title: const Text('Completion Popups'),
            subtitle: const Text('Show a popup when you hit today\'s goal'),
            secondary: const Icon(Icons.task_alt),
            value: settings.completionNotificationsEnabled,
            activeThumbColor: const Color(0xFF6C63FF),
            onChanged: settings.setCompletionNotificationsEnabled,
          ),
          SwitchListTile(
            title: const Text('Streak Milestones'),
            subtitle: const Text('Celebrate new best streaks'),
            secondary: const Icon(Icons.local_fire_department_outlined),
            value: settings.milestoneNotificationsEnabled,
            activeThumbColor: const Color(0xFF6C63FF),
            onChanged: settings.setMilestoneNotificationsEnabled,
          ),
          // Battery optimisation — critical for Realme / OPPO / Xiaomi devices
          // where aggressive power management silently kills scheduled alarms.
          ListTile(
            leading: const Icon(Icons.battery_saver_outlined,
                color: Color(0xFF6C63FF)),
            title: const Text('Fix Notifications (Battery)'),
            subtitle: const Text(
                'Disable battery optimisation so reminders fire reliably on Realme / OPPO / Xiaomi devices'),
            onTap: () async {
              final ns = NotificationService();
              final already = await ns.isIgnoringBatteryOptimizations();
              if (!context.mounted) return;
              if (already) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Battery optimisation is already disabled for this app.'),
                  ),
                );
              } else {
                await ns.requestBatteryOptimizationExemption();
              }
            },
          ),

          const _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Delete all habits and history'),
            onTap: () => _confirmClearAll(context),
          ),

          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                final build = snapshot.data?.buildNumber ?? '1';
                return Text(
                  '$version+$build',
                  style: const TextStyle(color: Colors.grey),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Built with Flutter'),
            subtitle: const Text('Material 3 + Hive + Provider'),
          ),

          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'LifeLoop🤍',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Build better habits, one day at a time',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete ALL habits and their history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final provider =
                  Provider.of<HabitProvider>(context, listen: false);
              for (final h in List.from(provider.habits)) {
                await provider.deleteHabit(h.id);
              }
              await NotificationService().cancelAll();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
