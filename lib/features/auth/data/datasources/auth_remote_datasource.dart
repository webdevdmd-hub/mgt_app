import 'package:firebase_auth/firebase_auth.dart';
import 'package:mgt_app/features/auth/domain/entities/user_entity.dart';
import 'package:mgt_app/features/auth/data/mappers/user_mapper.dart'; // if you have a mapper from Firebase User to your UserEntity
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Add Firestore instance if needed for user profiles
   final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<UserEntity>> getUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => UserEntity.fromJson(doc.data())).toList();
  }

  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('User not found');
      }
      // Map Firebase User to your UserEntity, customize as needed
      return UserMapper.fromFirebaseUser(firebaseUser);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserMapper.fromFirebaseUser(user);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserEntity> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
    required UserPermissions permissions, // Use the actual UserPermissions type
  }) async {
    try {
      // 1. 🔑 Create the user in Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final u = userCredential.user!;
      final String uid = u.uid;

      // 2. 📝 Build the UserEntity
      final newUser = UserEntity(
        id: uid,
        name: name,
        email: email,
        role: role,
        permissions: permissions, // 👈 Use the custom permissions from Admin form
        isActive: true,
        createdAt: DateTime.now(), 
        lastLogin: null,
      );

      // 3. 💾 Save the profile data to the 'users' collection using the Auth UID
      await _db.collection('users').doc(uid).set(newUser.toJson());

      // 4. (Optional): Send a password reset email immediately after creation
      // This forces the user to set a strong, secret password immediately.
      // await _auth.sendPasswordResetEmail(email: email); 
      
      return newUser;

    } on FirebaseAuthException catch (e) {
      // Re-throw specific, human-readable errors
      throw Exception(e.message ?? 'Failed to create user via Firebase Auth');
    } catch (e) {
      // General error handling
      throw Exception('Failed to provision new user and save profile: $e');
    }
  }
}