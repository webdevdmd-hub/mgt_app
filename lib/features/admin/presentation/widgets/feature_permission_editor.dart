import 'package:flutter/material.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Feature-based Permission Editor with expandable sections
class FeaturePermissionEditor extends StatefulWidget {
  final UserPermissions initialPermissions;
  final ValueChanged<UserPermissions> onPermissionsChanged;
  final String selectedRole;

  const FeaturePermissionEditor({
    super.key,
    required this.initialPermissions,
    required this.onPermissionsChanged,
    required this.selectedRole,
  });

  @override
  State<FeaturePermissionEditor> createState() => _FeaturePermissionEditorState();
}

class _FeaturePermissionEditorState extends State<FeaturePermissionEditor> {
  late UserPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.initialPermissions;
  }

  @override
  void didUpdateWidget(FeaturePermissionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update permissions if role changed
    if (oldWidget.selectedRole != widget.selectedRole) {
      // Schedule the update for after the current frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _permissions = UserPermissions.forRole(widget.selectedRole);
          });
          widget.onPermissionsChanged(_permissions);
        }
      });
    }
  }

  void _updatePermission(UserPermissions newPermissions) {
    setState(() {
      _permissions = newPermissions;
    });
    widget.onPermissionsChanged(newPermissions);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Manage Permissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Customize access permissions for this user',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const Divider(height: 24),

            // Dashboard Permission
            _buildFeatureSection(
              title: 'Dashboard',
              icon: Icons.dashboard_outlined,
              color: Colors.blue,
              permissions: [
                _PermissionItem(
                  label: 'View Dashboard',
                  value: _permissions.canViewDashboard,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canViewDashboard: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Leads Management
            _buildFeatureSection(
              title: 'Manage Leads',
              icon: Icons.person_add_outlined,
              color: Colors.green,
              permissions: [
                _PermissionItem(
                  label: 'View',
                  value: _permissions.canViewLeads,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canViewLeads: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Create',
                  value: _permissions.canCreateLeads,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canCreateLeads: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Edit',
                  value: _permissions.canEditLeads,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canEditLeads: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Delete',
                  value: _permissions.canDeleteLeads,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canDeleteLeads: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Projects Management
            _buildFeatureSection(
              title: 'Manage Projects',
              icon: Icons.folder_outlined,
              color: Colors.orange,
              permissions: [
                _PermissionItem(
                  label: 'View',
                  value: _permissions.canViewProjects,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canViewProjects: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Create',
                  value: _permissions.canCreateProjects,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canCreateProjects: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Edit',
                  value: _permissions.canEditProjects,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canEditProjects: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Delete',
                  value: _permissions.canDeleteProjects,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canDeleteProjects: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tasks Management
            _buildFeatureSection(
              title: 'Manage Tasks',
              icon: Icons.task_outlined,
              color: Colors.purple,
              permissions: [
                _PermissionItem(
                  label: 'View',
                  value: _permissions.canViewTasks,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canViewTasks: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Create',
                  value: _permissions.canCreateTasks,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canCreateTasks: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Edit',
                  value: _permissions.canEditTasks,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canEditTasks: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Delete',
                  value: _permissions.canDeleteTasks,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canDeleteTasks: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Admin & Advanced
            _buildFeatureSection(
              title: 'Admin & Advanced',
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.red,
              permissions: [
                _PermissionItem(
                  label: 'Manage Users',
                  value: _permissions.canManageUsers,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canManageUsers: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Manage Roles',
                  value: _permissions.canManageRoles,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canManageRoles: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Manage Settings',
                  value: _permissions.canManageSettings,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canManageSettings: v),
                  ),
                ),
                _PermissionItem(
                  label: 'Export Data',
                  value: _permissions.canExportData,
                  onChanged: (v) => _updatePermission(
                    _permissions.copyWith(canExportData: v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<_PermissionItem> permissions,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      children: permissions.map((perm) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  perm.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Switch(
                value: perm.value,
                onChanged: perm.onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PermissionItem {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  _PermissionItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });
}
