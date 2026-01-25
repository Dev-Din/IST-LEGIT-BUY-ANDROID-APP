import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserData(credential.user!.uid);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      UserModel user = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: AppConstants.roleCustomer, // Default role is customer
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(user.toJson());

      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? email,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;

      if (updates.isNotEmpty) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Initialize super-admin if needed (called on app startup)
  Future<void> initializeSuperAdminIfNeeded() async {
    try {
      // Step 1: Try to sign in first (user might already exist in Firebase Auth)
      User? authUser;
      try {
        await _auth.signInWithEmailAndPassword(
          email: AppConstants.superAdminEmail,
          password: AppConstants.superAdminPassword,
        );
        authUser = _auth.currentUser;
      } catch (signInError) {
        // User doesn't exist in Firebase Auth, create it
        try {
          UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: AppConstants.superAdminEmail,
            password: AppConstants.superAdminPassword,
          );
          authUser = credential.user;
        } catch (createError) {
          // User creation failed, abort
          return;
        }
      }

      // Step 2: Now that we're authenticated, create/update Firestore document
      if (authUser != null) {
        try {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(authUser.uid)
              .set({
            'email': AppConstants.superAdminEmail,
            'name': AppConstants.superAdminName,
            'role': AppConstants.roleSuperAdmin,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (firestoreError) {
          // Silently fail - Firestore error
        }
        
        // Step 3: Sign out so user must login manually
        await _auth.signOut();
      }
    } catch (e) {
      // Silently fail - don't crash app if super-admin creation fails
    }
  }
}
