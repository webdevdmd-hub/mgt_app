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
    return UserEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'sales',
      permissions: UserPermissions.forRole(json['role'] as String? ?? 'sales'),
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
        'isActive': isActive,
        'phone': phone,
        'avatar': avatar,
        'createdAt': createdAt,
        'lastLogin': lastLogin,
      };
}

@immutable
class UserPermissions {
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;
  final bool isSales;
  final bool isAdmin;

  const UserPermissions({
    this.canCreate = false,
    this.canRead = false,
    this.canUpdate = false,
    this.canDelete = false,
    this.isSales = false,
    this.isAdmin = false,
  });

  factory UserPermissions.forRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserPermissions.admin();
      case 'sales':
        return UserPermissions.sales();
      default:
        return const UserPermissions();
    }
  }

  factory UserPermissions.admin() {
    return const UserPermissions(
      canCreate: true,
      canRead: true,
      canUpdate: true,
      canDelete: true,
      isAdmin: true,
    );
  }

  factory UserPermissions.sales() {
    return const UserPermissions(
      canCreate: true,
      canRead: true,
      canUpdate: true,
      canDelete: false,
      isSales: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'canCreate': canCreate,
        'canRead': canRead,
        'canUpdate': canUpdate,
        'canDelete': canDelete,
        'isSales': isSales,
        'isAdmin': isAdmin,
      };
}
