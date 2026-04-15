import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../widgets/neu_box.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Padding(
                  padding: const EdgeInsets.bottom(12),
                  child: GestureDetector(
                    onTap: () => provider.markAsRead(notification.id),
                    child: NeuBox(
                      style: notification.isRead ? NeuStyle.pressed : NeuStyle.raised,
                      borderRadius: 16,
                      depth: notification.isRead ? 2 : 5,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getTypeIcon(notification.type),
                              color: _getTypeColor(notification.type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: TextStyle(
                                          fontWeight: notification.isRead
                                              ? FontWeight.w500
                                              : FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    color: NeuColors.textSecondary(isDark),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(notification.timestamp),
                                  style: TextStyle(
                                    color: NeuColors.textSecondary(isDark).withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: NeuColors.textSecondary(isDark).withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Your inbox is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: NeuColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'habit.reminder':
        return Icons.alarm_rounded;
      case 'streak.milestone':
        return Icons.local_fire_department_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'habit.reminder':
        return Colors.blue;
      case 'streak.milestone':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
