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
    DebugLogger.log(
      location: 'auth_provider.dart:signIn',
      message: 'AuthProvider.signIn called',
      data: {'email': email, 'passwordLength': password.length},
      hypothesisId: 'C',
    );
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      DebugLogger.log(
        location: 'auth_provider.dart:signIn',
        message: 'AuthProvider.signIn succeeded',
        data: {'userExists': _user != null, 'role': _user?.role, 'isSuperAdmin': _user?.role == AppConstants.roleSuperAdmin},
        hypothesisId: 'F',
      );

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
      DebugLogger.log(
        location: 'auth_provider.dart:signIn',
        message: 'AuthProvider.signIn failed',
        data: {'error': e.toString(), 'errorMessage': _error},
        hypothesisId: 'D',
      );
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
