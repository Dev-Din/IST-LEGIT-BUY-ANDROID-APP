import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/debug_logger.dart';

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
    DebugLogger.log(
      location: 'auth_service.dart:signInWithEmailAndPassword',
      message: 'signInWithEmailAndPassword called',
      data: {'email': email, 'passwordLength': password.length, 'emailTrimmed': email.trim()},
      hypothesisId: 'C',
    );
    try {
      DebugLogger.log(
        location: 'auth_service.dart:signInWithEmailAndPassword',
        message: 'Before Firebase Auth signInWithEmailAndPassword',
        data: {'email': email, 'expectedEmail': AppConstants.superAdminEmail, 'emailMatch': email.trim() == AppConstants.superAdminEmail},
        hypothesisId: 'D',
      );
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      DebugLogger.log(
        location: 'auth_service.dart:signInWithEmailAndPassword',
        message: 'Firebase Auth signInWithEmailAndPassword succeeded',
        data: {'uid': credential.user?.uid, 'email': credential.user?.email},
        hypothesisId: 'D',
      );
      var userData = await getUserData(credential.user!.uid);
      DebugLogger.log(
        location: 'auth_service.dart:signInWithEmailAndPassword',
        message: 'getUserData result',
        data: {'userDataExists': userData != null, 'role': userData?.role, 'expectedRole': AppConstants.roleSuperAdmin, 'roleMatch': userData?.role == AppConstants.roleSuperAdmin},
        hypothesisId: 'E',
      );

      // Repair: if Auth succeeded but Firestore user doc is missing, create it
      if (userData == null) {
        final firebaseUser = credential.user!;
        final repairUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
          role: AppConstants.roleCustomer,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(firebaseUser.uid)
            .set(repairUser.toJson());

        userData = repairUser;
      }

      return userData;
    } catch (e) {
      DebugLogger.log(
        location: 'auth_service.dart:signInWithEmailAndPassword',
        message: 'Firebase Auth signInWithEmailAndPassword failed',
        data: {'error': e.toString(), 'errorType': e.runtimeType.toString()},
        hypothesisId: 'D',
      );
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

      // Attempt Firestore write with one retry to avoid leaving Auth-only users
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(user.toJson());
      } catch (_) {
        // Retry once
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(user.toJson());
      }

      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    DebugLogger.log(
      location: 'auth_service.dart:getUserData',
      message: 'getUserData called',
      data: {'uid': uid},
      hypothesisId: 'E',
    );
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      final docData = doc.data() as Map<String, dynamic>?;
      DebugLogger.log(
        location: 'auth_service.dart:getUserData',
        message: 'Firestore document retrieved',
        data: {'docExists': doc.exists, 'hasData': docData != null, 'dataKeys': docData?.keys.toList(), 'role': docData?['role'], 'email': docData?['email']},
        hypothesisId: 'E',
      );

      if (doc.exists) {
        final userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>, uid);
        DebugLogger.log(
          location: 'auth_service.dart:getUserData',
          message: 'UserModel created from Firestore',
          data: {'role': userModel.role, 'expectedRole': AppConstants.roleSuperAdmin, 'roleMatch': userModel.role == AppConstants.roleSuperAdmin, 'email': userModel.email},
          hypothesisId: 'F',
        );
        return userModel;
      }
      DebugLogger.log(
        location: 'auth_service.dart:getUserData',
        message: 'Firestore document does not exist',
        data: {'uid': uid},
        hypothesisId: 'B',
      );
      return null;
    } catch (e) {
      DebugLogger.log(
        location: 'auth_service.dart:getUserData',
        message: 'getUserData Firestore error',
        data: {'error': e.toString(), 'errorType': e.runtimeType.toString()},
        hypothesisId: 'E',
      );
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
    DebugLogger.log(
      location: 'auth_service.dart:initializeSuperAdminIfNeeded',
      message: 'initializeSuperAdminIfNeeded called',
      data: {'email': AppConstants.superAdminEmail, 'passwordLength': AppConstants.superAdminPassword.length},
      hypothesisId: 'A',
    );
    try {
      // Step 1: Try to sign in first (user might already exist in Firebase Auth)
      User? authUser;
      try {
        await _auth.signInWithEmailAndPassword(
          email: AppConstants.superAdminEmail,
          password: AppConstants.superAdminPassword,
        );
        authUser = _auth.currentUser;
        DebugLogger.log(
          location: 'auth_service.dart:initializeSuperAdminIfNeeded',
          message: 'Superadmin sign-in succeeded',
          data: {'uid': authUser?.uid, 'email': authUser?.email},
          hypothesisId: 'A',
        );
      } catch (signInError) {
        DebugLogger.log(
          location: 'auth_service.dart:initializeSuperAdminIfNeeded',
          message: 'Superadmin sign-in failed, attempting creation',
          data: {'error': signInError.toString()},
          hypothesisId: 'A',
        );
        // User doesn't exist in Firebase Auth, create it
        try {
          UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: AppConstants.superAdminEmail,
            password: AppConstants.superAdminPassword,
          );
          authUser = credential.user;
          DebugLogger.log(
            location: 'auth_service.dart:initializeSuperAdminIfNeeded',
            message: 'Superadmin user created',
            data: {'uid': authUser?.uid, 'email': authUser?.email},
            hypothesisId: 'A',
          );
        } catch (createError) {
          DebugLogger.log(
            location: 'auth_service.dart:initializeSuperAdminIfNeeded',
            message: 'Superadmin user creation failed',
            data: {'error': createError.toString()},
            hypothesisId: 'A',
          );
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
          DebugLogger.log(
            location: 'auth_service.dart:initializeSuperAdminIfNeeded',
            message: 'Superadmin Firestore document created/updated',
            data: {'uid': authUser.uid, 'role': AppConstants.roleSuperAdmin},
            hypothesisId: 'A',
          );
        } catch (firestoreError) {
          DebugLogger.log(
            location: 'auth_service.dart:initializeSuperAdminIfNeeded',
            message: 'Superadmin Firestore document creation failed',
            data: {'error': firestoreError.toString()},
            hypothesisId: 'A',
          );
          // Silently fail - Firestore error
        }
        
        // Step 3: Sign out so user must login manually
        await _auth.signOut();
        DebugLogger.log(
          location: 'auth_service.dart:initializeSuperAdminIfNeeded',
          message: 'Superadmin signed out after initialization',
          data: {},
          hypothesisId: 'A',
        );
      }
    } catch (e) {
      DebugLogger.log(
        location: 'auth_service.dart:initializeSuperAdminIfNeeded',
        message: 'initializeSuperAdminIfNeeded exception',
        data: {'error': e.toString()},
        hypothesisId: 'A',
      );
      // Silently fail - don't crash app if super-admin creation fails
    }
  }
}
