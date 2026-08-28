import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/debug/reset_local_data.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_theme.dart';
import '../../../../core/ui/components/app_button.dart';
import '../../../../core/ui/components/app_text_field.dart';
import '../../../../core/ui/components/form_error_banner.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_validators.dart';

/// Login screen: email + password with validation and server errors.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  /// Debug-only recovery: wipe local data and clear the session so the next
  /// launch re-seeds a clean database (see core/debug/reset_local_data.dart).
  Future<void> _resetLocalData() async {
    await ref.read(resetLocalDataProvider)();
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final neo = Theme.of(context).extension<NeoTheme>()!;
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo + title
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: neo.accent,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                          border: Border.all(
                            color: neo.border,
                            width: neo.borderWidth,
                          ),
                          boxShadow: neo.shadowSm,
                        ),
                        child: Icon(
                          Icons.chat_bubble_rounded,
                          size: 36,
                          color: neo.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: neo.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Welcome back! Sign in to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: neo.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FormErrorBanner(message: auth.errorMessage),
                    if (auth.errorMessage != null)
                      const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Username',
                      controller: _usernameController,
                      hint: 'johndoe',
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: AuthValidators.username,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      validator: AuthValidators.password,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      label: 'Login',
                      onPressed: auth.isSubmitting ? null : _submit,
                      loading: auth.isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (kDebugMode)
                      TextButton(
                        onPressed: _resetLocalData,
                        child: Text(
                          'Reset local data (debug)',
                          style: TextStyle(
                            fontSize: 13,
                            color: neo.inkMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            "Don't have an account? ",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: neo.inkMuted,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Clear any auth error from this screen before
                            // switching tabs (the controller is shared).
                            ref
                                .read(authControllerProvider.notifier)
                                .clearError();
                            context.go('/register');
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: neo.ink,
                              decoration: TextDecoration.underline,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
