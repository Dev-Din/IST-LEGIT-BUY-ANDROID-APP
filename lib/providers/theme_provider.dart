import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/debug_logger.dart';

class ThemeProvider with ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeData get theme {
    // #region agent log
    DebugLogger.log(
      location: 'theme_provider.dart:13',
      message: 'ThemeProvider.theme getter called',
      data: {'_isDarkMode': _isDarkMode},
      hypothesisId: 'B',
    );
    // #endregion
    try {
      final themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
      // #region agent log
      DebugLogger.log(
        location: 'theme_provider.dart:21',
        message: 'Theme retrieved successfully',
        data: {'brightness': themeData.brightness.toString()},
        hypothesisId: 'B',
      );
      // #endregion
      return themeData;
    } catch (e) {
      // #region agent log
      DebugLogger.log(
        location: 'theme_provider.dart:30',
        message: 'Theme retrieval FAILED',
        data: {'error': e.toString()},
        hypothesisId: 'B',
      );
      // #endregion
      rethrow;
    }
  }

  ThemeProvider() {
    // #region agent log
    DebugLogger.log(
      location: 'theme_provider.dart:40',
      message: 'ThemeProvider constructor called',
      hypothesisId: 'B',
    );
    // #endregion
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    // #region agent log
    DebugLogger.log(
      location: 'theme_provider.dart:48',
      message: '_loadThemePreference() called',
      hypothesisId: 'B',
    );
    // #endregion
    try {
      _isDarkMode = await _themeService.isDarkMode();
      // #region agent log
      DebugLogger.log(
        location: 'theme_provider.dart:54',
        message: '_loadThemePreference() completed',
        data: {'_isDarkMode': _isDarkMode},
        hypothesisId: 'B',
      );
      // #endregion
      notifyListeners();
      // #region agent log
      DebugLogger.log(
        location: 'theme_provider.dart:60',
        message: 'notifyListeners() called',
        hypothesisId: 'B',
      );
      // #endregion
    } catch (e) {
      // #region agent log
      DebugLogger.log(
        location: 'theme_provider.dart:66',
        message: '_loadThemePreference() FAILED',
        data: {'error': e.toString()},
        hypothesisId: 'B',
      );
      // #endregion
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _themeService.saveThemePreference(_isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _themeService.saveThemePreference(_isDarkMode);
      notifyListeners();
    }
  }
}
