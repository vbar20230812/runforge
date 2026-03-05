import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:runforge/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Theme smoke test', (WidgetTester tester) async {
    // Test that the theme builds correctly
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const Scaffold(body: Text('Test')),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('App themes are not null', () {
    // Verify theme setup
    expect(AppTheme.lightTheme, isNotNull);
    expect(AppTheme.darkTheme, isNotNull);
  });
}
