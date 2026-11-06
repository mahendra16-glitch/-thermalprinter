import 'package:flutter/material.dart';
import '../models/print_job.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.connected() {
    return const StatusBadge(
      label: 'Connected',
      color: Color(0xFF10B981),
      icon: Icons.check_circle_rounded,
    );
  }

  factory StatusBadge.disconnected() {
    return const StatusBadge(
      label: 'Disconnected',
      color: Color(0xFFEF4444),
      icon: Icons.cancel_rounded,
    );
  }

  factory StatusBadge.connecting() {
    return const StatusBadge(
      label: 'Connecting',
      color: Color(0xFFF59E0B),
      icon: Icons.sync_rounded,
    );
  }

  factory StatusBadge.forJobStatus(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.pending:
        return const StatusBadge(
          label: 'Pending',
          color: Color(0xFF3B82F6),
          icon: Icons.hourglass_top_rounded,
        );
      case PrintJobStatus.printing:
        return const StatusBadge(
          label: 'Printing...',
          color: Color(0xFFF59E0B),
          icon: Icons.print_rounded,
        );
      case PrintJobStatus.printed:
        return const StatusBadge(
          label: 'Printed',
          color: Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
        );
      case PrintJobStatus.failed:
        return const StatusBadge(
          label: 'Failed',
          color: Color(0xFFEF4444),
          icon: Icons.error_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
