import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';
import '../providers/auth_controller.dart';

/// Splash screen: app logo + loading indicator while the session is restored.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Restore the session once; the router redirects based on the result.
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: neo.accent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: neo.border, width: neo.borderWidth),
                boxShadow: neo.shadowMd,
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 48,
                color: neo.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: neo.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: neo.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
