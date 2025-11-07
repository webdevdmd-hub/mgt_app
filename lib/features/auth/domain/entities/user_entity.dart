import 'package:flutter/foundation.dart';

@immutable
class UserEntity {
  final String id;
  final String name;
  final String email;
  final String role;
  final UserPermissions permissions;
  final bool isActive;
  final String? phone;
  final String? avatar;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'sales',
    required this.permissions,
    this.isActive = true,
    this.phone,
    this.avatar,
    this.createdAt,
    this.lastLogin,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String? ?? 'sales';

    // If permissions are stored in Firestore, use them
    // Otherwise fall back to role-based permissions for backward compatibility
    final UserPermissions permissions;
    if (json['permissions'] != null && json['permissions'] is Map) {
      permissions = UserPermissions.fromJson(json['permissions'] as Map<String, dynamic>);
    } else {
      permissions = UserPermissions.forRole(role);
    }

    return UserEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: role,
      permissions: permissions,
      isActive: json['isActive'] as bool? ?? true,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: json['createdAt']?.toDate(),
      lastLogin: json['lastLogin']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'permissions': permissions.toJson(),
        'isActive': isActive,
        'phone': phone,
        'avatar': avatar,
        'createdAt': createdAt,
        'lastLogin': lastLogin,
      };
}

@immutable
class UserPermissions {
  // Leads Permissions
  final bool canViewLeads;
  final bool canCreateLeads;
  final bool canEditLeads;
  final bool canDeleteLeads;

  // Projects Permissions
  final bool canViewProjects;
  final bool canCreateProjects;
  final bool canEditProjects;
  final bool canDeleteProjects;

  // Tasks Permissions
  final bool canViewTasks;
  final bool canCreateTasks;
  final bool canEditTasks;
  final bool canDeleteTasks;

  // Admin Permissions
  final bool canManageUsers;
  final bool canManageRoles;
  final bool canManageSettings;
  final bool canExportData;

  // Dashboard
  final bool canViewDashboard;

  const UserPermissions({
    this.canViewLeads = false,
    this.canCreateLeads = false,
    this.canEditLeads = false,
    this.canDeleteLeads = false,
    this.canViewProjects = false,
    this.canCreateProjects = false,
    this.canEditProjects = false,
    this.canDeleteProjects = false,
    this.canViewTasks = false,
    this.canCreateTasks = false,
    this.canEditTasks = false,
    this.canDeleteTasks = false,
    this.canManageUsers = false,
    this.canManageRoles = false,
    this.canManageSettings = false,
    this.canExportData = false,
    this.canViewDashboard = false,
  });

  factory UserPermissions.forRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserPermissions.admin();
      case 'sales':
        return UserPermissions.sales();
      case 'marketing':
        return UserPermissions.marketing();
      case 'production':
        return UserPermissions.production();
      case 'accounts':
        return UserPermissions.accounts();
      case 'store':
        return UserPermissions.store();
      case 'estimation':
        return UserPermissions.estimation();
      case 'delivery':
        return UserPermissions.delivery();
      default:
        return UserPermissions.user();
    }
  }

  factory UserPermissions.admin() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: true,
      canCreateLeads: true,
      canEditLeads: true,
      canDeleteLeads: true,
      canViewProjects: true,
      canCreateProjects: true,
      canEditProjects: true,
      canDeleteProjects: true,
      canViewTasks: true,
      canCreateTasks: true,
      canEditTasks: true,
      canDeleteTasks: true,
      canManageUsers: true,
      canManageRoles: true,
      canManageSettings: true,
      canExportData: true,
    );
  }

  factory UserPermissions.sales() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: true,
      canCreateLeads: true,
      canEditLeads: true,
      canDeleteLeads: false,
      canViewProjects: true,
      canCreateProjects: false,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewTasks: true,
      canCreateTasks: true,
      canEditTasks: true,
      canDeleteTasks: false,
    );
  }

  factory UserPermissions.marketing() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: true,
      canCreateLeads: false,
      canEditLeads: false,
      canDeleteLeads: false,
      canViewProjects: true,
      canCreateProjects: false,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewTasks: false,
      canCreateTasks: false,
      canEditTasks: false,
      canDeleteTasks: false,
      canExportData: true,
    );
  }

  factory UserPermissions.production() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: false,
      canCreateLeads: false,
      canEditLeads: false,
      canDeleteLeads: false,
      canViewProjects: true,
      canCreateProjects: false,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewTasks: true,
      canCreateTasks: false,
      canEditTasks: true,
      canDeleteTasks: false,
    );
  }

  factory UserPermissions.accounts() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: false,
      canCreateLeads: false,
      canEditLeads: false,
      canDeleteLeads: false,
      canViewProjects: true,
      canCreateProjects: false,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewTasks: false,
      canCreateTasks: false,
      canEditTasks: false,
      canDeleteTasks: false,
      canExportData: true,
    );
  }

  factory UserPermissions.store() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: false,
      canCreateLeads: false,
      canEditLeads: false,
      canDeleteLeads: false,
      canViewProjects: true,
      canCreateProjects: false,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewTasks: true,
      canCreateTasks: false,
      canEditTasks: false,
      canDeleteTasks: false,
    );
  }

  factory UserPermissions.estimation() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: false,
      canCreateLeads: false,
      canEditLeads: false,
      canDeleteLeads: false,
      canViewProjects: true,
      canCreateProjects: true,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewTasks: false,
      canCreateTasks: false,
      canEditTasks: false,
      canDeleteTasks: false,
    );
  }

  factory UserPermissions.delivery() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewLeads: false,
      canCreateLeads: false,
      canEditLeads: false,
      canDeleteLeads: false,
      canViewProjects: false,
      canCreateProjects: false,
      canEditProjects: false,
      canDeleteProjects: false,
      canViewTasks: true,
      canCreateTasks: false,
      canEditTasks: false,
      canDeleteTasks: false,
    );
  }

  factory UserPermissions.user() {
    return const UserPermissions(
      canViewDashboard: true,
      canViewTasks: true,
    );
  }

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      canViewDashboard: json['canViewDashboard'] as bool? ?? false,
      canViewLeads: json['canViewLeads'] as bool? ?? false,
      canCreateLeads: json['canCreateLeads'] as bool? ?? false,
      canEditLeads: json['canEditLeads'] as bool? ?? false,
      canDeleteLeads: json['canDeleteLeads'] as bool? ?? false,
      canViewProjects: json['canViewProjects'] as bool? ?? false,
      canCreateProjects: json['canCreateProjects'] as bool? ?? false,
      canEditProjects: json['canEditProjects'] as bool? ?? false,
      canDeleteProjects: json['canDeleteProjects'] as bool? ?? false,
      canViewTasks: json['canViewTasks'] as bool? ?? false,
      canCreateTasks: json['canCreateTasks'] as bool? ?? false,
      canEditTasks: json['canEditTasks'] as bool? ?? false,
      canDeleteTasks: json['canDeleteTasks'] as bool? ?? false,
      canManageUsers: json['canManageUsers'] as bool? ?? false,
      canManageRoles: json['canManageRoles'] as bool? ?? false,
      canManageSettings: json['canManageSettings'] as bool? ?? false,
      canExportData: json['canExportData'] as bool? ?? false,
    );
  }

  UserPermissions copyWith({
    bool? canViewDashboard,
    bool? canViewLeads,
    bool? canCreateLeads,
    bool? canEditLeads,
    bool? canDeleteLeads,
    bool? canViewProjects,
    bool? canCreateProjects,
    bool? canEditProjects,
    bool? canDeleteProjects,
    bool? canViewTasks,
    bool? canCreateTasks,
    bool? canEditTasks,
    bool? canDeleteTasks,
    bool? canManageUsers,
    bool? canManageRoles,
    bool? canManageSettings,
    bool? canExportData,
  }) {
    return UserPermissions(
      canViewDashboard: canViewDashboard ?? this.canViewDashboard,
      canViewLeads: canViewLeads ?? this.canViewLeads,
      canCreateLeads: canCreateLeads ?? this.canCreateLeads,
      canEditLeads: canEditLeads ?? this.canEditLeads,
      canDeleteLeads: canDeleteLeads ?? this.canDeleteLeads,
      canViewProjects: canViewProjects ?? this.canViewProjects,
      canCreateProjects: canCreateProjects ?? this.canCreateProjects,
      canEditProjects: canEditProjects ?? this.canEditProjects,
      canDeleteProjects: canDeleteProjects ?? this.canDeleteProjects,
      canViewTasks: canViewTasks ?? this.canViewTasks,
      canCreateTasks: canCreateTasks ?? this.canCreateTasks,
      canEditTasks: canEditTasks ?? this.canEditTasks,
      canDeleteTasks: canDeleteTasks ?? this.canDeleteTasks,
      canManageUsers: canManageUsers ?? this.canManageUsers,
      canManageRoles: canManageRoles ?? this.canManageRoles,
      canManageSettings: canManageSettings ?? this.canManageSettings,
      canExportData: canExportData ?? this.canExportData,
    );
  }

  Map<String, dynamic> toJson() => {
        'canViewDashboard': canViewDashboard,
        'canViewLeads': canViewLeads,
        'canCreateLeads': canCreateLeads,
        'canEditLeads': canEditLeads,
        'canDeleteLeads': canDeleteLeads,
        'canViewProjects': canViewProjects,
        'canCreateProjects': canCreateProjects,
        'canEditProjects': canEditProjects,
        'canDeleteProjects': canDeleteProjects,
        'canViewTasks': canViewTasks,
        'canCreateTasks': canCreateTasks,
        'canEditTasks': canEditTasks,
        'canDeleteTasks': canDeleteTasks,
        'canManageUsers': canManageUsers,
        'canManageRoles': canManageRoles,
        'canManageSettings': canManageSettings,
        'canExportData': canExportData,
      };
}
