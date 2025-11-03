import 'package:flutter/material.dart';

enum StatusType {
  pending,
  inProgress,
  completed,
  cancelled,
  // add more as needed
}

// Add an extension to StatusType for string conversion
extension StatusTypeExtension on StatusType {
  // A helper to easily convert the enum value to a canonical string
  String get name => toString().split('.').last;

  // Static method to convert a string (e.g., 'pending') to the enum value
  static StatusType fromString(String statusString) {
    try {
      // Find the enum value whose name matches the input string (case-insensitive)
      return StatusType.values.firstWhere(
        (e) => e.name.toLowerCase() == statusString.toLowerCase(),
      );
    } catch (e) {
      // Handle cases where the string doesn't match any enum value
      // You can throw an error, log it, or return a default status.
      // Returning 'pending' as a safe default:
      debugPrint(
        'Warning: Unknown status string "$statusString". Defaulting to pending.',
      );
      return StatusType.pending;
    }
  }
}

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final bool showIcon;

  const StatusBadge({super.key, required this.status, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    final data = _statusData[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) Icon(data.icon, color: data.color, size: 16),
          if (showIcon) const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              color: data.color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusData {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  const _StatusData({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });
}

const Map<StatusType, _StatusData> _statusData = {
  StatusType.pending: _StatusData(
    label: 'Pending',
    color: Colors.orange,
    background: Color(0xFFFFF4E5),
    icon: Icons.hourglass_empty,
  ),
  StatusType.inProgress: _StatusData(
    label: 'In Progress',
    color: Colors.blue,
    background: Color(0xFFE5F1FF),
    icon: Icons.autorenew,
  ),
  StatusType.completed: _StatusData(
    label: 'Completed',
    color: Colors.green,
    background: Color(0xFFE6F4EA),
    icon: Icons.check_circle,
  ),
  StatusType.cancelled: _StatusData(
    label: 'Cancelled',
    color: Colors.red,
    background: Color(0xFFFFE6E6),
    icon: Icons.cancel,
  ),
};
