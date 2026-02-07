import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isSuperAdmin => _user?.role == AppConstants.roleSuperAdmin;
  bool get isAdmin => _user?.role == AppConstants.roleAdmin || isSuperAdmin;
  bool get isCustomer => _user?.role == AppConstants.roleCustomer;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check initial auth state immediately
    try {
      final currentUser = _authService.currentUser;
      
      if (currentUser != null) {
        _isLoading = true;
        notifyListeners();
        await loadUserData(currentUser.uid);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
    
    // Set up listener for future changes
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        await loadUserData(firebaseUser.uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.getUserData(uid);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    // #region agent log
    try {
      final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
      logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"C","location":"auth_provider.dart:72","message":"AuthProvider.signIn called","data":{"email":email,"passwordLength":password.length},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
    } catch (_) {}
    // #endregion
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"F","location":"auth_provider.dart:81","message":"AuthProvider.signIn succeeded","data":{"userExists":_user!=null,"role":_user?.role,"isSuperAdmin":_user?.role==AppConstants.roleSuperAdmin},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion

      if (_user == null) {
        _error = 'Could not load account. Please try again or contact support.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // #region agent log
      try {
        final logFile = File('/home/nuru/Development/IST-EDUCATION-DIPLOMA-SOFTWARE-DEV/ist_flutter_android_app/.cursor/debug.log');
        logFile.writeAsStringSync('${jsonEncode({"sessionId":"debug-session","runId":"run1","hypothesisId":"D","location":"auth_provider.dart:87","message":"AuthProvider.signIn failed","data":{"error":e.toString(),"errorMessage":_error},"timestamp":DateTime.now().millisecondsSinceEpoch})}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (_user == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updateUserProfile(
        uid: _user!.id,
        name: name,
        email: email,
      );

      if (name != null) {
        _user = _user!.copyWith(name: name);
      }
      if (email != null) {
        _user = _user!.copyWith(email: email);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
