import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/user_form.dart';
import 'package:go_router/go_router.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _roleFilter = 'all';

  static const roles = <String>[
    'admin',
    'sales manager',
    'sales executive',
    'estimation',
    'accounts',
    'store',
    'production',
    'delivery',
    'marketing',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to dashboard",
          onPressed: () {
            context.go('/dashboard');
          },
        ),
        title: const Text('User Management'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (ctx) => const UserForm(),
          );
        },
        label: const Text('New User'),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search + Filters
            Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchCtrl,
                    leading: const Icon(Icons.search),
                    hintText: 'Search by name or email',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  tooltip: 'Filter by role',
                  initialValue: _roleFilter,
                  onSelected: (v) => setState(() => _roleFilter = v),
                  itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                    const PopupMenuItem(value: 'all', child: Text('All roles')),
                    const PopupMenuDivider(),
                    ...roles.map(
                      (r) => PopupMenuItem(value: r, child: Text(r)),
                    ),
                  ],
                  child: FilledButton.tonalIcon(
                    onPressed: null,
                    icon: const Icon(Icons.filter_list),
                    label: Text(_roleFilter == 'all' ? 'All' : _roleFilter),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  final docs = snap.data?.docs ?? [];
                  final filtered = docs.where((d) {
                    final data = d.data();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '')
                        .toString()
                        .toLowerCase();
                    final role = (data['role'] ?? '').toString().toLowerCase();
                    final q = _searchCtrl.text.trim().toLowerCase();
                    final matchesQuery =
                        q.isEmpty || name.contains(q) || email.contains(q);
                    final matchesRole =
                        _roleFilter == 'all' || role == _roleFilter;
                    return matchesQuery && matchesRole;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No users found'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      final data = doc.data();
                      final name = (data['name'] ?? '').toString();
                      final email = (data['email'] ?? '').toString();
                      final role = (data['role'] ?? '').toString();
                      final isActive = (data['isActive'] as bool?) ?? true;

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(_initials(name.isEmpty ? email : name)),
                        ),
                        title: Text(name.isEmpty ? email : name),
                        subtitle: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(email),
                            Chip(label: Text(role)),
                            Chip(
                              label: Text(isActive ? 'Active' : 'Disabled'),
                              backgroundColor: isActive
                                  ? Colors.green.withAlpha((0.10 * 255).round())
                                  : Colors.red.withAlpha((0.10 * 255).round()),
                            ),
                          ],
                        ),
                        // open edit sheet on tap
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (ctx) =>
                                UserForm(userId: doc.id, initialData: data),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (v) async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(doc.id)
                                      .update({'isActive': v});
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'User ${v ? 'enabled' : 'disabled'}',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    builder: (ctx) => UserForm(
                                      userId: doc.id,
                                      initialData: data,
                                    ),
                                  );
                                } else if (value == 'role') {
                                  await _changeRole(context, doc.id, role);
                                } else if (value == 'delete') {
                                  await _deleteUser(context, doc.id, email);
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'role',
                                  child: Text('Change role'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    String uid,
    String currentRole,
  ) async {
    // cache messenger before any async gaps
    final messenger = ScaffoldMessenger.of(context);

    final availableRoles = _UserManagementScreenState.roles;

    // Handle backward compatibility: map old "sales" role to "sales executive"
    String selected = currentRole;
    if (currentRole == 'sales') {
      selected = 'sales executive';
    }

    // Ensure selected role exists in availableRoles, otherwise default to first role
    if (!availableRoles.contains(selected)) {
      selected = availableRoles.first;
    }

    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change role'),
        content: StatefulBuilder(
          builder: (ctx, setState) => DropdownButtonFormField<String>(
            initialValue: selected,
            items: availableRoles
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) => setState(() => selected = v ?? selected),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(selected),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (res == null || res == currentRole) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': res,
      });
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Role updated')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteUser(
    BuildContext context,
    String uid,
    String email,
  ) async {
    // cache messenger before any async gaps
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Are you sure you want to delete $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('User deleted')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
