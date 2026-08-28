import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';

/// Route names for typed navigation.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const chat = '/chat';
  static const chatConversation = '/chat/:conversationId';
}

/// Builds the app router.
///
/// Auth-aware redirect:
/// - unknown status → splash (session restore)
/// - unauthenticated → /login (except splash/login/register)
/// - authenticated → /chat (when landing on splash/login/register)
///
/// The router reads the latest auth state via [currentAuthState]; [ChatApp]
/// calls `router.refresh()` whenever auth changes so redirects re-evaluate.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final auth = currentAuthState;
      final isAuthed = auth.isAuthenticated;
      final status = auth.status;
      final location = state.matchedLocation;

      final onPublic = location == Routes.login || location == Routes.register;

      // Session restore still in progress: stay on splash.
      if (status == AuthStatus.unknown) {
        return Routes.splash;
      }

      // Not authenticated: only splash (as a brief holding screen) and auth
      // pages are allowed; once status is known, leave splash immediately.
      if (!isAuthed) {
        return onPublic ? null : Routes.login;
      }

      // Authenticated: bounce auth pages to chat.
      if (location == Routes.splash || onPublic) return Routes.chat;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: Routes.chatConversation,
        builder: (context, state) => ChatScreen(
          initialConversationId: state.pathParameters['conversationId'],
        ),
      ),
    ],
  );
});

/// Latest auth state consumed by the router redirect. Updated by [ChatApp]
/// whenever the auth controller emits.
AuthState currentAuthState = const AuthState();
