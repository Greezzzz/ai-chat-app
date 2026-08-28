// Full end-to-end test on a real Android device/emulator.
//
// Runs against a real Hive box (persistent storage) and real
// SharedPreferences, exercising the exact code path that failed manually:
// register → session restore on relaunch → login → chat → streaming.
//
// Run with:
//   ~/.local/bin/flutter test integration_test/app_test.dart -d emulator-5554
//
// Notes:
// - No `pumpAndSettle` (the splash's CircularProgressIndicator animates
//   forever and would hang it) — use explicit `pump(Duration)`.
// - Assumes a clean-ish device; it seeds its own account and clears the
//   session at the end so reruns do not collide.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:chat_app/core/storage/seed_data.dart';
import 'package:chat_app/core/storage/storage_providers.dart';
import 'package:chat_app/features/auth/presentation/providers/auth_controller.dart';
import 'package:chat_app/features/auth/presentation/screens/login_screen.dart';
import 'package:chat_app/features/auth/presentation/screens/register_screen.dart';
import 'package:chat_app/main.dart';

/// Replicates the startup sequence from `main()`: init storage + seed, then
/// return a container ready to host [ChatApp].
Future<ProviderContainer> startContainer() async {
  final container = ProviderContainer();
  await container.read(storageInitProvider.future);
  await container.read(seedDataProvider.future);
  return container;
}

/// Pumps a fresh [ChatApp] on a container and pumps the splash redirect.
Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const ChatApp()),
  );
  // Let the splash restore the session and the router redirect.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('E2E: register → relaunch session → logout → login → chat → stream',
      (tester) async {
    final email = 'e2e_${DateTime.now().millisecondsSinceEpoch}@example.com';
    const password = 'password123';

    // --- Register a fresh account. ---
    var container = await startContainer();
    addTearDown(container.dispose);
    await pumpApp(tester, container);

    // From the splash we should land on /login (unauthenticated, no session).
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Register'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(RegisterScreen), findsOneWidget);

    // Fill the register form.
    await tester.enterText(find.byType(TextFormField).at(0), 'e2e_user');
    await tester.enterText(find.byType(TextFormField).at(1), email);
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tester.enterText(find.byType(TextFormField).at(3), password);
    await tester.tap(find.text('Create Account'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Registration auto-logs in → chat screen.
    expect(find.text('How can I help you today?'), findsOneWidget);

    // --- Simulate a fresh launch: a new container must restore the session
    //     from persistent SharedPreferences and land straight on chat. ---
    container.dispose();
    final relaunchContainer = await startContainer();
    addTearDown(relaunchContainer.dispose);
    await pumpApp(tester, relaunchContainer);

    // Splash redirects straight to chat because the session persisted.
    expect(find.text('How can I help you today?'), findsOneWidget);

    // --- Send a chat message and watch the assistant stream. ---
    await tester.enterText(find.byType(TextField), 'Halo, apa kabar?');
    await tester.pump(const Duration(milliseconds: 100));

    // Tap the send button.
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(milliseconds: 50));

    // Streaming in progress → the assistant bubble shows a cursor.
    expect(find.textContaining('▌'), findsOneWidget);

    // Let the mock stream finish (thinking 400ms + chunks).
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    // Full response landed and the cursor is gone.
    expect(find.textContaining('Halo! Senang bertemu'), findsOneWidget);
    expect(find.textContaining('▌'), findsNothing);

    // --- The new conversation is persisted in the history drawer. ---
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    // Drawer shows the auto-generated title from the first message.
    expect(find.textContaining('Halo'), findsWidgets);

    // --- Clean up: logout so reruns (and later manual use) start fresh. ---
    container = relaunchContainer;
    await container
        .read(authControllerProvider.notifier)
        .logout();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}