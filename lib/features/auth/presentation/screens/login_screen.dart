import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/login_hero.dart';
import '../widgets/sign_up_sheet.dart';

/// Layar masuk — identitas visual v3.
///
/// Alur profesional: hero brand + 3 poin nilai, form email + kata sandi
/// (validasi format langsung), tombol Masuk penuh, divider "atau", tombol
/// Google outlined, lanjutkan sebagai tamu, dan link daftar yang membuka
/// [SignUpSheet]. Widget ini tidak pernah menyentuh Firebase secara
/// langsung; semua melalui use case.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _BusyMode { none, email, google, guest }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _BusyMode _busy = _BusyMode.none;
  String? _emailError;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isBusy => _busy != _BusyMode.none;

  void _fail(AppLocalizations l10n, Object error, String fallback) {
    if (!mounted) return;
    final message = switch (error) {
      AppFailure failure => failureMessage(failure, l10n),
      ArgumentError(:final message) => _argumentMessage(message, l10n),
      _ => fallback,
    };
    setState(() => _errorMessage = message);
  }

  /// `ArgumentError.message` dari use case berupa kunci l10n atau pesan
  /// validasi domain Bahasa Indonesia.
  String _argumentMessage(Object message, AppLocalizations l10n) {
    return switch (message) {
      'loginInvalidEmail' => l10n.loginInvalidEmail,
      'loginPasswordTooShort' => l10n.loginPasswordTooShort,
      'loginPasswordMismatch' => l10n.loginPasswordMismatch,
      _ => '$message',
    };
  }

  bool _validateLogin(AppLocalizations l10n) {
    final email = _emailController.text.trim();
    setState(() {
      _emailError = email.isEmpty
          ? l10n.loginRequiredField
          : !_looksLikeEmail(email)
          ? l10n.loginInvalidEmail
          : null;
      _errorMessage = null;
    });
    return _emailError == null && _passwordController.text.isNotEmpty;
  }

  bool _looksLikeEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return false;
    final dot = email.indexOf('.', at + 1);
    return dot > at + 1 && dot < email.length - 1;
  }

  Future<void> _submitEmail() async {
    final l10n = AppLocalizations.of(context);
    if (_isBusy || !_validateLogin(l10n)) return;
    setState(() => _busy = _BusyMode.email);
    try {
      await ref
          .read(signInWithEmailProvider)
          .call(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } on Object catch (error) {
      _fail(l10n, error, l10n.stateErrorUnknown);
    } finally {
      if (mounted) setState(() => _busy = _BusyMode.none);
    }
  }

  Future<void> _submitGoogle() async {
    final l10n = AppLocalizations.of(context);
    if (_isBusy) return;
    setState(() => _busy = _BusyMode.google);
    try {
      await ref.read(signInWithGoogleProvider).call();
    } on Object catch (error) {
      _fail(l10n, error, l10n.stateErrorUnknown);
    } finally {
      if (mounted) setState(() => _busy = _BusyMode.none);
    }
  }

  Future<void> _submitGuest() async {
    final l10n = AppLocalizations.of(context);
    if (_isBusy) return;
    setState(() => _busy = _BusyMode.guest);
    try {
      await ref.read(signInAnonymouslyProvider).call();
    } on Object catch (error) {
      _fail(l10n, error, l10n.loginGuestFailed);
    } finally {
      if (mounted) setState(() => _busy = _BusyMode.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spaceXl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DesignTokens.maxContentWidth,
              ),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LoginHero(),
                    const SizedBox(height: DesignTokens.spaceXl),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.loginWelcomeBack,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    AuthTextField(
                      controller: _emailController,
                      label: l10n.loginEmailLabel,
                      errorText: _emailError,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      enabled: !_isBusy,
                      onSubmitted: (_) => _submitEmail(),
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    AuthTextField(
                      controller: _passwordController,
                      label: l10n.loginPasswordLabel,
                      hint: l10n.loginPasswordHint,
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      enabled: !_isBusy,
                      onSubmitted: (_) => _submitEmail(),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    FilledButton(
                      onPressed: _isBusy ? null : _submitEmail,
                      child: _busy == _BusyMode.email
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.loginSignInWithEmail),
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    const OrDivider(),
                    const SizedBox(height: DesignTokens.spaceMd),
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _submitGoogle,
                      icon: _busy == _BusyMode.google
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(
                        l10n.loginSignInWithGoogle,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    TextButton.icon(
                      onPressed: _isBusy ? null : _submitGuest,
                      icon: _busy == _BusyMode.guest
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_outline_rounded, size: 18),
                      label: Text(l10n.loginContinueAsGuest),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: DesignTokens.spaceMd),
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
                    const SizedBox(height: DesignTokens.spaceLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.loginNoAccount,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () => SignUpSheet.show(context),
                          child: Text(l10n.loginSignUpLink),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Text(
                      l10n.loginPrivacyNote,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
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
