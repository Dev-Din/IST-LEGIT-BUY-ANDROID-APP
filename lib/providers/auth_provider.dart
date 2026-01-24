import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/debug_logger.dart';

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
    // #region agent log
    DebugLogger.log(
      location: 'auth_provider.dart:22',
      message: 'AuthProvider constructor called',
      hypothesisId: 'C',
    );
    // #endregion
    _init();
  }

  Future<void> _init() async {
    // #region agent log
    DebugLogger.log(
      location: 'auth_provider.dart:29',
      message: '_init() called - setting up authStateChanges listener',
      hypothesisId: 'C',
    );
    // #endregion
    
    // Check initial auth state immediately
    try {
      final currentUser = _authService.currentUser;
      // #region agent log
      DebugLogger.log(
        location: 'auth_provider.dart:37',
        message: 'Initial auth state checked',
        data: {'hasCurrentUser': currentUser != null, 'uid': currentUser?.uid},
        hypothesisId: 'C',
      );
      // #endregion
      
      if (currentUser != null) {
        _isLoading = true;
        notifyListeners();
        await loadUserData(currentUser.uid);
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
        // #region agent log
        DebugLogger.log(
          location: 'auth_provider.dart:50',
          message: 'No current user - set _isLoading=false and notified listeners',
          hypothesisId: 'C',
        );
        // #endregion
      }
    } catch (e) {
      // #region agent log
      DebugLogger.log(
        location: 'auth_provider.dart:57',
        message: 'Initial auth state check FAILED',
        data: {'error': e.toString()},
        hypothesisId: 'C',
      );
      // #endregion
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
    
    // Set up listener for future changes
    _authService.authStateChanges.listen((firebaseUser) async {
      // #region agent log
      DebugLogger.log(
        location: 'auth_provider.dart:70',
        message: 'authStateChanges event received',
        data: {'hasUser': firebaseUser != null, 'uid': firebaseUser?.uid},
        hypothesisId: 'C',
      );
      // #endregion
      if (firebaseUser != null) {
        await loadUserData(firebaseUser.uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData(String uid) async {
    // #region agent log
    DebugLogger.log(
      location: 'auth_provider.dart:88',
      message: 'loadUserData() called',
      data: {'uid': uid},
      hypothesisId: 'C',
    );
    // #endregion
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.getUserData(uid);
      // #region agent log
      DebugLogger.log(
        location: 'auth_provider.dart:98',
        message: 'loadUserData() completed',
        data: {
          'hasUser': _user != null,
          'userRole': _user?.role,
          'userEmail': _user?.email,
        },
        hypothesisId: 'C',
      );
      // #endregion
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // #region agent log
      DebugLogger.log(
        location: 'auth_provider.dart:110',
        message: 'loadUserData() FAILED',
        data: {'error': e.toString()},
        hypothesisId: 'C',
      );
      // #endregion
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
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
