import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/home_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/super_admin_dashboard.dart';
import 'services/auth_service.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/config/firebase_options.dart';
import 'widgets/emulator_banner_filter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Connect to local emulators in debug mode
    if (kDebugMode) {
      try {
        // Firestore emulator
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        
        // Auth emulator
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      } catch (e) {
        rethrow;
      }
    }
    
    // Initialize super-admin if needed
    try {
      await AuthService().initializeSuperAdminIfNeeded();
    } catch (e) {
      // Silently fail - don't crash app if super-admin initialization fails
    }
  } catch (e) {
    
    // Show helpful error to user instead of crashing
    final isWebError = e.toString().contains('FirebaseOptions') || e.toString().contains('web');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (isWebError) ...[
                  const Text(
                    'Web App Configuration Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To fix this issue:\n\n'
                    '1. Go to Firebase Console: https://console.firebase.google.com\n'
                    '2. Select project: ist-flutter-android-app\n'
                    '3. Click ⚙️ → Project settings\n'
                    '4. Scroll to "Your apps" section\n'
                    '5. If no Web app exists, click "Add app" → Web (</> icon)\n'
                    '6. Copy the appId from the config\n'
                    '7. Update lib/core/config/firebase_options.dart line 60\n'
                    '   Replace YOUR_WEB_APP_ID_PLACEHOLDER with the actual appId\n\n'
                    'OR run on Android instead:\n'
                    'flutter run -d android',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 14),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${e.toString()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please check your Firebase configuration.\nSee FIREBASE_WEB_SETUP.md for details.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }
  
  // Add global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };
  
  runApp(const LegitBuyApp());
}

class LegitBuyApp extends StatelessWidget {
  const LegitBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          try {
            final theme = themeProvider.theme;
            
            return MaterialApp(
              title: AppConstants.appName,
              theme: theme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              debugShowCheckedModeBanner: false,
              home: const AuthWrapper(),
              builder: (context, child) {
                // Wrap child with EmulatorBannerFilter to remove Firebase emulator warning banner
                final widget = child ?? const Scaffold(body: Center(child: Text('No widget to display')));
                return EmulatorBannerFilter(child: widget);
              },
            );
          } catch (e) {
            return MaterialApp(
              title: AppConstants.appName,
              home: Scaffold(
                body: Center(
                  child: Text('Error: $e'),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          try {
            return const LoginScreen();
          } catch (e) {
            return Scaffold(
              body: Center(child: Text('Login Error: $e')),
            );
          }
        }

        // Role-based navigation
        if (authProvider.isSuperAdmin) {
          return const SuperAdminDashboard();
        } else if (authProvider.isAdmin) {
          return const AdminDashboard();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}
