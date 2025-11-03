// Permission matrix and helpers for role-based access control.
//
// - Define permissions as an enum for type-safety.
// - Provide a default mapping from role -> permissions set.
// - Helpers: check permission, list allowed routes (simple mapping).
//
// Adjust roles/permissions to match your app's requirements.

enum Permission {
  viewDashboard,
  viewLeads,
  createLeads,
  editLeads,
  viewProjects,
  createProjects,
  editProjects,
  viewTasks,
  createTasks,
  editTasks,
  manageUsers,
  manageRoles,
  manageSettings,
  exportData,
}

/// Default permission sets per role. Keys are case-insensitive role names.
final Map<String, Set<Permission>> defaultRolePermissions = {
  'admin': Permission.values.toSet(),
  'sales': {
    Permission.viewDashboard,
    Permission.viewLeads,
    Permission.createLeads,
    Permission.viewProjects,
    Permission.viewTasks,
    Permission.createTasks,
  },
  'marketing': {
    Permission.viewDashboard,
    Permission.viewLeads,
    Permission.viewProjects,
    Permission.exportData,
  },
  'production': {
    Permission.viewDashboard,
    Permission.viewProjects,
    Permission.viewTasks,
    Permission.editTasks,
  },
  'accounts': {
    Permission.viewDashboard,
    Permission.viewProjects,
    Permission.exportData,
  },
  'store': {
    Permission.viewDashboard,
    Permission.viewProjects,
    Permission.viewTasks,
  },
  'estimation': {
    Permission.viewDashboard,
    Permission.viewProjects,
    Permission.createProjects,
  },
  'delivery': {Permission.viewDashboard, Permission.viewTasks},
  // fallback role for any authenticated user without explicit mapping
  'user': {Permission.viewDashboard, Permission.viewTasks},
};

/// Normalize role string to lookup in the map.
String _normalizeRole(String? role) => (role ?? 'user').trim().toLowerCase();

/// Returns the permission set for [role]. Falls back to 'user' set if unknown.
Set<Permission> permissionsForRole(String? role) {
  final key = _normalizeRole(role);
  return defaultRolePermissions[key] ?? defaultRolePermissions['user']!.toSet();
}

/// Returns true if [role] grants [permission].
bool hasPermission(String? role, Permission permission) {
  return permissionsForRole(role).contains(permission);
}

/// Simple route -> required permission map. Use route names (e.g. '/admin') or
/// route identifiers matching your GoRouter names.
final Map<String, Permission> routePermissionMap = {
  '/admin': Permission.manageUsers,
  '/user-management': Permission.manageUsers,
  '/dashboard': Permission.viewDashboard,
  '/leads': Permission.viewLeads,
  '/leads/create': Permission.createLeads,
  '/projects': Permission.viewProjects,
  '/projects/create': Permission.createProjects,
  '/tasks': Permission.viewTasks,
  '/tasks/create': Permission.createTasks,
  '/settings': Permission.manageSettings,
};

/// Check whether [role] can access [route]. If route not mapped, returns true
/// (open by default). Adjust to be deny-by-default if preferred.
bool canAccessRoute(String? role, String route, {bool openByDefault = true}) {
  // exact match first
  final req = routePermissionMap[route];
  if (req != null) {
    return hasPermission(role, req);
  }

  // try simple prefix match (useful for '/projects/123')
  final entry = routePermissionMap.entries.firstWhere(
    (e) => route.startsWith('${e.key}/'),
    orElse: () => MapEntry('', Permission.viewDashboard),
  );
  if (entry.key.isNotEmpty) {
    return hasPermission(role, entry.value);
  }


  return openByDefault;
}


/// Convenience: return allowed routes for a role (from routePermissionMap).
List<String> allowedRoutesForRole(String? role) {
  final perms = permissionsForRole(role);
  return routePermissionMap.entries
      .where((e) => perms.contains(e.value))
      .map((e) => e.key)
      .toList();
}

