import 'package:flutter/material.dart';
import 'neu_box.dart';

class StreakBadge extends StatelessWidget {
  final int streak;
  final bool compact;

  const StreakBadge({super.key, required this.streak, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) return const SizedBox.shrink();
    final color = _streakColor(streak);

    if (compact) {
      return NeuBox(
        style: NeuStyle.raised,
        borderRadius: 10,
        depth: 3,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department, color: color, size: 13),
            const SizedBox(width: 3),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return NeuBox(
      style: NeuStyle.raised,
      borderRadius: 20,
      depth: 5,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: color, size: 22),
          const SizedBox(width: 8),
          Text(
            '$streak ${streak == 1 ? 'day' : 'days'} streak',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _streakColor(int s) {
    if (s >= 30) return const Color(0xFFFF6B00);
    if (s >= 14) return const Color(0xFFFF8C00);
    if (s >= 7) return const Color(0xFFFFB300);
    return const Color(0xFFFFCA28);
  }
}
