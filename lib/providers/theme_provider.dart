import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeData get theme {
    return _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      _isDarkMode = await _themeService.isDarkMode();
      notifyListeners();
    } catch (e) {
      // Silently fail
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
