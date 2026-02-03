import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
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
    // #region agent log
    try {
      final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
      logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"auth_service.dart:22","message":"signInWithEmailAndPassword called","data":{"email":email,"passwordLength":password.length,"emailTrimmed":email.trim()},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    try {
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"auth_service.dart:25","message":"Before Firebase Auth signInWithEmailAndPassword","data":{"email":email,"expectedEmail":AppConstants.superAdminEmail,"emailMatch":email.trim()==AppConstants.superAdminEmail},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"auth_service.dart:30","message":"Firebase Auth signInWithEmailAndPassword succeeded","data":{"uid":credential.user?.uid,"email":credential.user?.email},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      final userData = await getUserData(credential.user!.uid);
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"auth_service.dart:33","message":"getUserData result","data":{"userDataExists":userData!=null,"role":userData?.role,"expectedRole":AppConstants.roleSuperAdmin,"roleMatch":userData?.role==AppConstants.roleSuperAdmin},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      return userData;
    } catch (e) {
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"auth_service.dart:36","message":"Firebase Auth signInWithEmailAndPassword failed","data":{"error":e.toString(),"errorType":e.runtimeType.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
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
    // #region agent log
    try {
      final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
      logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"auth_service.dart:67","message":"getUserData called","data":{"uid":uid},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    try {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        final docData = doc.data() as Map<String, dynamic>?;
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"auth_service.dart:72","message":"Firestore document retrieved","data":{"docExists":doc.exists,"hasData":docData!=null,"dataKeys":docData?.keys.toList(),"role":docData?["role"],"email":docData?["email"]},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion

      if (doc.exists) {
        final userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>, uid);
        // #region agent log
        try {
          final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
          logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"F","location":"auth_service.dart:75","message":"UserModel created from Firestore","data":{"role":userModel.role,"expectedRole":AppConstants.roleSuperAdmin,"roleMatch":userModel.role==AppConstants.roleSuperAdmin,"email":userModel.email},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
        return userModel;
      }
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"B","location":"auth_service.dart:78","message":"Firestore document does not exist","data":{"uid":uid},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      return null;
    } catch (e) {
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"E","location":"auth_service.dart:81","message":"getUserData Firestore error","data":{"error":e.toString(),"errorType":e.runtimeType.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
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
    // #region agent log
    try {
      final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
      logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:115","message":"initializeSuperAdminIfNeeded called","data":{"email":AppConstants.superAdminEmail,"passwordLength":AppConstants.superAdminPassword.length},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    try {
      // Step 1: Try to sign in first (user might already exist in Firebase Auth)
      User? authUser;
      try {
        await _auth.signInWithEmailAndPassword(
          email: AppConstants.superAdminEmail,
          password: AppConstants.superAdminPassword,
        );
        authUser = _auth.currentUser;
        // #region agent log
        try {
          final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
          logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:123","message":"Superadmin sign-in succeeded","data":{"uid":authUser?.uid,"email":authUser?.email},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
      } catch (signInError) {
        // #region agent log
        try {
          final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
          logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:127","message":"Superadmin sign-in failed, attempting creation","data":{"error":signInError.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
        // User doesn't exist in Firebase Auth, create it
        try {
          UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: AppConstants.superAdminEmail,
            password: AppConstants.superAdminPassword,
          );
          authUser = credential.user;
          // #region agent log
          try {
            final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
            logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:132","message":"Superadmin user created","data":{"uid":authUser?.uid,"email":authUser?.email},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
          } catch (_) {}
          // #endregion
        } catch (createError) {
          // #region agent log
          try {
            final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
            logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:135","message":"Superadmin user creation failed","data":{"error":createError.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
          } catch (_) {}
          // #endregion
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
          // #region agent log
          try {
            final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
            logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:149","message":"Superadmin Firestore document created/updated","data":{"uid":authUser.uid,"role":AppConstants.roleSuperAdmin},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
          } catch (_) {}
          // #endregion
        } catch (firestoreError) {
          // #region agent log
          try {
            final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
            logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:152","message":"Superadmin Firestore document creation failed","data":{"error":firestoreError.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
          } catch (_) {}
          // #endregion
          // Silently fail - Firestore error
        }
        
        // Step 3: Sign out so user must login manually
        await _auth.signOut();
        // #region agent log
        try {
          final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
          logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:156","message":"Superadmin signed out after initialization","data":{},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
      }
    } catch (e) {
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"A","location":"auth_service.dart:160","message":"initializeSuperAdminIfNeeded exception","data":{"error":e.toString()},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      // Silently fail - don't crash app if super-admin creation fails
    }
  }
}
