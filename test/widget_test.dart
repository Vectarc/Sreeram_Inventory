// Flutter app smoke test for Sree Ram Company
//
// This verifies the app launches without crashing.
// For real device/emulator tests, use integration_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:sreeramcompany/main.dart';
import 'package:sreeramcompany/theme_provider.dart';

void main() {
  testWidgets('App launches and shows splash screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // Verify the splash screen renders (Sree Ram Company text visible)
    expect(find.text('Sree Ram Company'), findsOneWidget);
  });
}
