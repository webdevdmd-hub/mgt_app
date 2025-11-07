import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/foundation.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImplFirebase implements AuthRepository {
  final fb.FirebaseAuth _auth;
  final fs.FirebaseFirestore _db;

  final Set<String> allowedAdminEmails;

  AuthRepositoryImplFirebase({
    fb.FirebaseAuth? auth,
    fs.FirebaseFirestore? firestore,
    this.allowedAdminEmails = const {'webdevdmd@gmail.com'},
  }) : _auth = auth ?? fb.FirebaseAuth.instance,
       _db = firestore ?? fs.FirebaseFirestore.instance {
    // optional: ensure persistence (helps offline fallback)
    _db.settings = const fs.Settings(persistenceEnabled: true);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;

    try {
      final profile = await _getProfile(u.uid);

      // Check 1: Profile exists and is active
      if (profile == null || (profile['isActive'] == false)) {
        await _auth.signOut();
        return null;
      }

      final role = (profile['role'] as String?)?.toLowerCase() ?? 'sales';

      // Load permissions from Firestore if available, otherwise use role-based defaults
      final UserPermissions permissions;
      if (profile['permissions'] != null && profile['permissions'] is Map) {
        permissions = UserPermissions.fromJson(profile['permissions'] as Map<String, dynamic>);
      } else {
        permissions = UserPermissions.forRole(role);
      }

      return UserEntity(
        id: u.uid,
        name:
            (profile['name'] as String?) ??
            (u.displayName ?? (u.email ?? 'User')),
        email: u.email ?? '',
        role: role,
        permissions: permissions,
        isActive: true,
        createdAt: u.metadata.creationTime,
        lastLogin: u.metadata.lastSignInTime,
      );
    } catch (e) {
      // debugPrint is now defined due to the import above
      debugPrint('Error fetching user profile in getCurrentUser: $e');
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<List<UserEntity>> getUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs.map((doc) => UserEntity.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final u = cred.user!;
    var profile = await _getProfile(u.uid); // now with timeout + fallback

    // seed admin profile if allowlisted
    final emailLc = (u.email ?? '').toLowerCase();
    if (profile == null &&
        emailLc.isNotEmpty &&
        allowedAdminEmails.contains(emailLc)) {
      final seeded = {
        'name': u.displayName ?? 'Admin',
        'email': u.email ?? email,
        'role': 'admin',
        'isActive': true,
        'createdAt': fs.FieldValue.serverTimestamp(),
      };
      try {
        await _db
            .collection('users')
            .doc(u.uid)
            .set(seeded, fs.SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
        // read back from server if possible so timestamps resolve
        profile = await _getProfile(u.uid, serverOnly: true) ?? seeded;
      } on TimeoutException {
        // fallback to cache; continue with seeded to avoid blocking UX
        profile = seeded;
      } on fs.FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          await _auth.signOut();
          throw Exception('Not allowed to auto-create profile. Ask admin.');
        }
        rethrow;
      }
    }

    final isActive = profile != null && (profile['isActive'] != false);
    if (!isActive) {
      await _auth.signOut();
      throw Exception(
        'Your account is not active or not provisioned. Contact admin.',
      );
    }

    final Map<String, dynamic> p = profile;
    final role = (p['role'] as String?)?.toLowerCase() ?? 'sales';

    // Load permissions from Firestore if available, otherwise use role-based defaults
    final UserPermissions permissions;
    if (p['permissions'] != null && p['permissions'] is Map) {
      permissions = UserPermissions.fromJson(p['permissions'] as Map<String, dynamic>);
    } else {
      permissions = UserPermissions.forRole(role);
    }

    return UserEntity(
      id: u.uid,
      name: (p['name'] as String?) ?? (u.displayName ?? email),
      email: u.email ?? email,
      role: role,
      permissions: permissions,
      isActive: true,
      createdAt: u.metadata.creationTime,
      lastLogin: u.metadata.lastSignInTime,
    );
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<UserEntity> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
    required UserPermissions permissions,
  }) async {
    try {
      // 1. 🔑 Create the user in Firebase Authentication
      // This allows the user to log in later via email/password.
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final u = userCredential.user!;
      final String uid = u.uid;

      final newUser = UserEntity(
        id: uid,
        name: name,
        email: email,
        role: role,
        permissions: permissions,
        isActive: true,
        phone: null,
        avatar: null,
        createdAt: DateTime.now(),
        lastLogin: null,
      );

      await _db.collection('users').doc(uid).set(newUser.toJson());

      // 4. (Optional but recommended): Send a password reset email
      // This forces the user to set a strong, secret password immediately.
      await _auth.sendPasswordResetEmail(email: email);

      return newUser;
    } on fb.FirebaseAuthException catch (_) {
      // Re-throw specific, human-readable errors (e.g., 'email-already-in-use')
      rethrow;
    } catch (e) {
      // General error handling
      throw Exception('Failed to provision new user: $e');
    }
  }

  Future<Map<String, dynamic>?> _getProfile(
    String uid, {
    bool serverOnly = false,
  }) async {
    try {
      final docRef = _db.collection('users').doc(uid);
      final snap = serverOnly
          ? await docRef
                .get(fs.GetOptions(source: fs.Source.server))
                .timeout(const Duration(seconds: 8))
          : await docRef.get().timeout(const Duration(seconds: 8));
      if (!snap.exists) return null;
      return snap.data();
    } on TimeoutException {
      // fallback to cache to avoid hanging the app
      final cacheSnap = await _db
          .collection('users')
          .doc(uid)
          .get(const fs.GetOptions(source: fs.Source.cache));
      if (!cacheSnap.exists) return null;
      return cacheSnap.data();
    }
  }
}
