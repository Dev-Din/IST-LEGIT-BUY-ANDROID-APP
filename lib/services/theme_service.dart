import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static const String _lightTheme = 'light';
  static const String _darkTheme = 'dark';

  // Get saved theme preference
  Future<String?> getThemePreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeKey);
    } catch (e) {
      return null;
    }
  }

  // Save theme preference
  Future<void> saveThemePreference(bool isDarkMode) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        isDarkMode ? _darkTheme : _lightTheme,
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Check if dark mode is enabled
  Future<bool> isDarkMode() async {
    String? theme = await getThemePreference();
    return theme == _darkTheme;
  }
}
