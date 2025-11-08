import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User Selector Widget - Dropdown for assigning tasks/projects/leads to users
///
/// Usage:
/// ```dart
/// UserSelector(
///   selectedUserId: assignedTo,
///   onUserSelected: (userId, userName) {
///     setState(() {
///       assignedTo = userId;
///       assignedToName = userName;
///     });
///   },
///   filterRole: 'sales executive', // Optional: filter by role
/// )
/// ```
class UserSelector extends ConsumerStatefulWidget {
  final String? selectedUserId;
  final Function(String? userId, String? userName) onUserSelected;
  final String? filterRole; // Optional: filter users by role
  final String? label;
  final bool enabled;

  const UserSelector({
    super.key,
    this.selectedUserId,
    required this.onUserSelected,
    this.filterRole,
    this.label,
    this.enabled = true,
  });

  @override
  ConsumerState<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends ConsumerState<UserSelector> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildUsersQuery(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.label ?? 'Assign To',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline),
            ),
            items: const [],
            onChanged: null,
            hint: const Text('Loading users...'),
          );
        }

        if (snapshot.hasError) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: widget.label ?? 'Assign To',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person_outline),
              errorText: 'Error loading users',
            ),
            items: const [],
            onChanged: null,
          );
        }

        final users = snapshot.data?.docs ?? [];

        // Sort users by name in memory (to avoid needing Firestore composite index)
        users.sort((a, b) {
          final nameA = (a.data()['name'] as String? ?? '').toLowerCase();
          final nameB = (b.data()['name'] as String? ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        // Build dropdown items
        final items = users.map((doc) {
          final data = doc.data();
          final name = data['name'] as String? ?? 'Unknown';
          //final email = data['email'] as String? ?? '';
          final role = data['role'] as String? ?? '';

          return DropdownMenuItem<String>(
            value: doc.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(name),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (role.isNotEmpty)
                        Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList();

        // Add "Unassigned" option
        items.insert(
          0,
          DropdownMenuItem<String>(
            value: null,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person_off_outlined, size: 16),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Unassigned',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );

        // Validate that selectedUserId exists in the items list
        // If not, default to null (unassigned)
        String? validatedValue;
        if (widget.selectedUserId != null) {
          final userExists = users.any((doc) => doc.id == widget.selectedUserId);
          if (userExists) {
            validatedValue = widget.selectedUserId;
          }
          // If user doesn't exist (inactive/deleted/filtered), leave as null
        }

        return DropdownButtonFormField<String>(
          key: ValueKey(widget.selectedUserId), // Force rebuild when selection changes
          value: validatedValue,
          decoration: InputDecoration(
            labelText: widget.label ?? 'Assign To',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person_outline),
            enabled: widget.enabled,
          ),
          items: items,
          onChanged: widget.enabled
              ? (String? userId) {
                  if (userId == null) {
                    widget.onUserSelected(null, null);
                  } else {
                    // Find the selected user's name
                    final selectedUser = users.firstWhere(
                      (doc) => doc.id == userId,
                      orElse: () => users.first,
                    );
                    final userName = selectedUser.data()['name'] as String? ?? 'Unknown';
                    widget.onUserSelected(userId, userName);
                  }
                }
              : null,
          isExpanded: true,
          hint: const Text('Select user to assign'),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildUsersQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('isActive', isEqualTo: true);

    // Filter by role if specified
    if (widget.filterRole != null && widget.filterRole!.isNotEmpty) {
      query = query.where('role', isEqualTo: widget.filterRole);
    }

    // Note: Removed .orderBy('name') to avoid requiring Firestore composite index
    // Sorting is done in memory instead (see line 75-79)
    return query.snapshots();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
