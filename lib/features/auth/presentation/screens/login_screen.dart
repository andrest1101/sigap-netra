import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../widgets/login_form.dart';

/// Layar masuk.
///
/// Mengikuti `docs/ui_spec.md`: form email dan kata sandi, tombol Google, dan
/// penargetan state error yang ramah. Widget ini tidak pernah menyentuh Firebase
/// secara langsung; semua melalui use case.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(signInWithEmailProvider)
          .call(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(failure));
    } on Object {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.stateErrorUnknown);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogle() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isGoogleSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(signInWithGoogleProvider).call();
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(failure));
    } on Object {
      if (!mounted) return;
      setState(() => _errorMessage = l10n.stateErrorUnknown);
    } finally {
      if (mounted) setState(() => _isGoogleSubmitting = false);
    }
  }

  String _messageFor(AppFailure failure) =>
      failure.message(AppLocalizations.of(context));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isBusy = _isSubmitting || _isGoogleSubmitting;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceXl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesignTokens.maxContentWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  Text(
                    l10n.loginTitle,
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text(
                    l10n.loginSubtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceXxl),
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    onSubmitEmail: isBusy ? null : _submitEmail,
                    onSubmitGoogle: isBusy ? null : _submitGoogle,
                    isEmailSubmitting: _isSubmitting,
                    isGoogleSubmitting: _isGoogleSubmitting,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: DesignTokens.spaceLg),
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(DesignTokens.spaceMd),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusButton,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 20,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: DesignTokens.spaceSm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
