// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ist_flutter_android_app/main.dart';
import 'package:ist_flutter_android_app/providers/auth_provider.dart';
import 'package:ist_flutter_android_app/providers/product_provider.dart';
import 'package:ist_flutter_android_app/providers/cart_provider.dart';
import 'package:ist_flutter_android_app/providers/order_provider.dart';
import 'package:ist_flutter_android_app/providers/theme_provider.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const LegitBuyApp(),
      ),
    );

    // Wait for async initialization
    await tester.pumpAndSettle();

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
