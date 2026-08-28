import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/storage/seed_data.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_controller.dart';
import 'features/chat/presentation/providers/chat_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage and seed demo data before the first frame.
  final container = ProviderContainer();
  await container.read(storageInitProvider.future);
  await container.read(seedDataProvider.future);

  runApp(UncontrolledProviderScope(container: container, child: const ChatApp()));
}

class ChatApp extends ConsumerStatefulWidget {
  const ChatApp({super.key});

  @override
  ConsumerState<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends ConsumerState<ChatApp> {
  late final GoRouter _router = ref.read(appRouterProvider);

  @override
  void initState() {
    super.initState();
    currentAuthState = ref.read(authControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Re-run the router redirect whenever auth state changes.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      currentAuthState = next;
      // Leaving the session (logout / expiry / failed restore) must clear the
      // chat state so the next login starts fresh — no stale conversation.
      if (next.status == AuthStatus.unauthenticated) {
        ref.read(chatControllerProvider.notifier).reset();
      }
      _router.refresh();
    });

    return MaterialApp.router(
      title: 'Chatly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
