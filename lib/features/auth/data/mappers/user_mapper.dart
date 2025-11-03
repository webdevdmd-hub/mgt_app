import 'package:firebase_auth/firebase_auth.dart';
import 'package:mgt_app/features/auth/domain/entities/user_entity.dart';

class UserMapper {
  static UserEntity fromFirebaseUser(User user) {
    const defaultRole = 'sales';

    return UserEntity(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      role: defaultRole,
      // CORRECTED: Use the static factory to get permissions based on the defaultRole
      permissions: UserPermissions.forRole(defaultRole),
      isActive: true,
      createdAt: user.metadata.creationTime,
      lastLogin: user.metadata.lastSignInTime,
    );
  }
}
