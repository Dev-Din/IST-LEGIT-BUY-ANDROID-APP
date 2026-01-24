import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
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
import 'core/utils/debug_logger.dart';
import 'core/theme/app_theme.dart';
import 'core/config/firebase_options.dart';

void main() async {
  // #region agent log
  DebugLogger.log(
    location: 'main.dart:15',
    message: 'main() entry - WidgetsFlutterBinding.ensureInitialized() called',
    hypothesisId: 'A',
  );
  // #endregion
  WidgetsFlutterBinding.ensureInitialized();
  
  // #region agent log
  DebugLogger.log(
    location: 'main.dart:17',
    message: 'Before Firebase.initializeApp()',
    hypothesisId: 'A',
  );
  // #endregion
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // #region agent log
    DebugLogger.log(
      location: 'main.dart:40',
      message: 'Firebase.initializeApp() completed successfully',
      data: {'platform': kIsWeb ? 'web' : 'mobile'},
      hypothesisId: 'A',
    );
    // #endregion
    
    // Initialize super-admin if needed
    try {
      await AuthService().initializeSuperAdminIfNeeded();
      // #region agent log
      DebugLogger.log(
        location: 'main.dart:52',
        message: 'Super-admin initialization completed',
        hypothesisId: 'A',
      );
      // #endregion
    } catch (e) {
      // Silently fail - don't crash app if super-admin initialization fails
      // #region agent log
      DebugLogger.log(
        location: 'main.dart:60',
        message: 'Super-admin initialization failed (non-critical)',
        data: {'error': e.toString()},
        hypothesisId: 'A',
      );
      // #endregion
    }
  } catch (e, stackTrace) {
    // #region agent log
    DebugLogger.log(
      location: 'main.dart:50',
      message: 'Firebase.initializeApp() FAILED',
      data: {'error': e.toString(), 'stackTrace': stackTrace.toString()},
      hypothesisId: 'A',
    );
    // #endregion
    
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
  
  // #region agent log
  DebugLogger.log(
    location: 'main.dart:33',
    message: 'Calling runApp()',
    hypothesisId: 'A',
  );
  // #endregion
  
  // Add global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    // #region agent log
    DebugLogger.log(
      location: 'main.dart:67',
      message: 'FlutterError.onError caught',
      data: {
        'exception': details.exception.toString(),
        'stack': details.stack.toString(),
        'library': details.library,
      },
      hypothesisId: 'A',
    );
    // #endregion
    FlutterError.presentError(details);
  };
  
  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    // #region agent log
    DebugLogger.log(
      location: 'main.dart:80',
      message: 'PlatformDispatcher.onError caught',
      data: {
        'error': error.toString(),
        'stack': stack.toString(),
      },
      hypothesisId: 'A',
    );
    // #endregion
    return true;
  };
  
  runApp(const LegitBuyApp());
}

class LegitBuyApp extends StatelessWidget {
  const LegitBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // #region agent log
    DebugLogger.log(
      location: 'main.dart:47',
      message: 'LegitBuyApp.build() called',
      hypothesisId: 'B',
    );
    // #endregion
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:52',
            message: 'Creating AuthProvider',
            hypothesisId: 'D',
          );
          // #endregion
          try {
            final provider = AuthProvider();
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:58',
              message: 'AuthProvider created successfully',
              hypothesisId: 'D',
            );
            // #endregion
            return provider;
          } catch (e) {
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:65',
              message: 'AuthProvider creation FAILED',
              data: {'error': e.toString()},
              hypothesisId: 'D',
            );
            // #endregion
            rethrow;
          }
        }),
        ChangeNotifierProvider(create: (_) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:75',
            message: 'Creating ProductProvider',
            hypothesisId: 'D',
          );
          // #endregion
          try {
            final provider = ProductProvider();
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:82',
              message: 'ProductProvider created successfully',
              hypothesisId: 'D',
            );
            // #endregion
            return provider;
          } catch (e) {
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:90',
              message: 'ProductProvider creation FAILED',
              data: {'error': e.toString()},
              hypothesisId: 'D',
            );
            // #endregion
            rethrow;
          }
        }),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:87',
            message: 'Creating ThemeProvider',
            hypothesisId: 'B',
          );
          // #endregion
          try {
            final provider = ThemeProvider();
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:93',
              message: 'ThemeProvider created successfully',
              hypothesisId: 'B',
            );
            // #endregion
            return provider;
          } catch (e) {
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:100',
              message: 'ThemeProvider creation FAILED',
              data: {'error': e.toString()},
              hypothesisId: 'B',
            );
            // #endregion
            rethrow;
          }
        }),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:112',
            message: 'Consumer<ThemeProvider> builder called',
            data: {'isDarkMode': themeProvider.isDarkMode},
            hypothesisId: 'B',
          );
          // #endregion
          
          try {
            final theme = themeProvider.theme;
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:120',
              message: 'Theme retrieved successfully',
              data: {'themeBrightness': theme.brightness.toString()},
              hypothesisId: 'B',
            );
            // #endregion
            
            return MaterialApp(
              title: AppConstants.appName,
              theme: theme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              debugShowCheckedModeBanner: false,
              home: const AuthWrapper(),
              builder: (context, child) {
                // #region agent log
                DebugLogger.log(
                  location: 'main.dart:181',
                  message: 'MaterialApp builder called',
                  data: {'childIsNull': child == null},
                  hypothesisId: 'B',
                );
                // #endregion
                // Just return child - don't override it
                return child ?? const Scaffold(body: Center(child: Text('No widget to display')));
              },
            );
          } catch (e, stackTrace) {
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:133',
              message: 'MaterialApp build FAILED',
              data: {'error': e.toString(), 'stackTrace': stackTrace.toString()},
              hypothesisId: 'B',
            );
            // #endregion
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
    // #region agent log
    DebugLogger.log(
      location: 'main.dart:155',
      message: 'AuthWrapper.build() called',
      hypothesisId: 'C',
    );
    // #endregion
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // #region agent log
        DebugLogger.log(
          location: 'main.dart:161',
          message: 'AuthProvider Consumer builder called',
          data: {
            'isLoading': authProvider.isLoading,
            'isAuthenticated': authProvider.isAuthenticated,
            'isAdmin': authProvider.isAdmin,
            'hasUser': authProvider.user != null,
          },
          hypothesisId: 'C',
        );
        // #endregion
        
        if (authProvider.isLoading) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:175',
            message: 'Showing loading indicator',
            hypothesisId: 'C',
          );
          // #endregion
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:184',
            message: 'User not authenticated - showing LoginScreen',
            hypothesisId: 'C',
          );
          // #endregion
          try {
            return const LoginScreen();
          } catch (e) {
            // #region agent log
            DebugLogger.log(
              location: 'main.dart:192',
              message: 'LoginScreen build FAILED',
              data: {'error': e.toString()},
              hypothesisId: 'C',
            );
            // #endregion
            return Scaffold(
              body: Center(child: Text('Login Error: $e')),
            );
          }
        }

        // Role-based navigation
        if (authProvider.isSuperAdmin) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:430',
            message: 'User is super-admin - showing SuperAdminDashboard',
            hypothesisId: 'C',
          );
          // #endregion
          return const SuperAdminDashboard();
        } else if (authProvider.isAdmin) {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:438',
            message: 'User is admin - showing AdminDashboard',
            hypothesisId: 'C',
          );
          // #endregion
          return const AdminDashboard();
        } else {
          // #region agent log
          DebugLogger.log(
            location: 'main.dart:446',
            message: 'User is customer - showing HomeScreen',
            hypothesisId: 'C',
          );
          // #endregion
          return const HomeScreen();
        }
      },
    );
  }
}
