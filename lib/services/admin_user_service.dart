import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kDebugMode, defaultTargetPlatform, TargetPlatform;

/// Admin-only callables: create user (Auth + Firestore), delete user (Auth + Firestore).
class AdminUserService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  AdminUserService() {
    if (kDebugMode) {
      final emulatorHost = defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost';
      _functions.useFunctionsEmulator(emulatorHost, 5001);
    }
  }

  /// Create a new user. Requires admin or superadmin. Returns { success, uid, email, name, role }.
  Future<Map<String, dynamic>> createUserByAdmin({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final callable = _functions.httpsCallable('createUserByAdmin');
    final result = await callable.call(<String, dynamic>{
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      'role': role == 'admin' ? 'admin' : 'customer',
    });
    final data = result.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to create user');
    }
    return data;
  }

  /// Delete a user (Auth + Firestore). Requires admin or superadmin. Cannot delete superadmin.
  Future<void> deleteUser(String userId) async {
    final callable = _functions.httpsCallable('deleteUser');
    final result = await callable.call(<String, dynamic>{'userId': userId});
    final data = result.data as Map<String, dynamic>?;
    if (data == null || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Failed to delete user');
    }
  }
}
