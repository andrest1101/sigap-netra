import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/auth_providers.dart';
import 'auth_text_field.dart';

/// Sheet bawah pendaftaran akun: nama opsional + email + kata sandi +
/// konfirmasi.
///
/// Dibuka dari layar masuk via [SignUpSheet.show]. Validasi dilakukan
/// berlapis: format langsung di field (email, panjang, cocok) + aturan
/// penuh di use case saat submit. Error Firebase (email sudah dipakai,
/// dsb.) tampil sebagai banner di dalam sheet, bukan menutup sheet.
class SignUpSheet extends ConsumerStatefulWidget {
  const SignUpSheet({super.key});

  /// Menampilkan sheet daftar. Mengembalikan true bila akun berhasil dibuat
  /// (router otomatis pindah via redirect auth).
  static Future<bool> show(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusSheet),
        ),
      ),
      builder: (context) => const SignUpSheet(),
    );
    return created ?? false;
  }

  @override
  ConsumerState<SignUpSheet> createState() => _SignUpSheetState();
}

class _SignUpSheetState extends ConsumerState<SignUpSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validateFields(AppLocalizations l10n) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    setState(() {
      _emailError = email.isEmpty
          ? l10n.loginRequiredField
          : !_looksLikeEmail(email)
          ? l10n.loginInvalidEmail
          : null;
      _passwordError = password.isEmpty
          ? l10n.loginRequiredField
          : password.length < 6
          ? l10n.loginPasswordTooShort
          : null;
      _confirmError = confirm.isEmpty
          ? l10n.loginRequiredField
          : confirm != password
          ? l10n.loginPasswordMismatch
          : null;
      _submitError = null;
    });
    return _emailError == null &&
        _passwordError == null &&
        _confirmError == null;
  }

  /// Cek cepat format email di presentation (aturan penuh ada di use case).
  bool _looksLikeEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) return false;
    final dot = email.indexOf('.', at + 1);
    return dot > at + 1 && dot < email.length - 1;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!mounted || _isSubmitting) return;
    if (!_validateFields(l10n)) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(signUpWithEmailProvider)
          .call(
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmController.text,
            displayName: _nameController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() => _submitError = _argumentMessage(error, l10n));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      setState(() => _submitError = failureMessage(failure, l10n));
    } on Object {
      if (!mounted) return;
      setState(() => _submitError = l10n.loginSignUpFailed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// `ArgumentError.message` dari use case berupa kunci l10n bila pesannya
  /// cocok dengan salah satu string terjemahan; selain itu tampilkan apa
  /// adanya (pesan validasi domain Bahasa Indonesia).
  String _argumentMessage(ArgumentError error, AppLocalizations l10n) {
    return switch (error.message) {
      'loginInvalidEmail' => l10n.loginInvalidEmail,
      'loginPasswordTooShort' => l10n.loginPasswordTooShort,
      'loginPasswordMismatch' => l10n.loginPasswordMismatch,
      _ => '${error.message}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacePage,
        DesignTokens.spaceMd,
        DesignTokens.spacePage,
        bottom + DesignTokens.spacePage,
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              l10n.loginSignUpTitle,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceXs),
            Text(
              l10n.loginSignUpSubtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            AuthTextField(
              controller: _nameController,
              label: l10n.loginNameLabel,
              hint: l10n.loginNameHint,
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            AuthTextField(
              controller: _emailController,
              label: l10n.loginEmailLabel,
              errorText: _emailError,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !_isSubmitting,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            AuthTextField(
              controller: _passwordController,
              label: l10n.loginPasswordLabel,
              hint: l10n.loginPasswordHint,
              errorText: _passwordError,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !_isSubmitting,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            AuthTextField(
              controller: _confirmController,
              label: l10n.loginConfirmPasswordLabel,
              errorText: _confirmError,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !_isSubmitting,
              onSubmitted: (_) => _submit(),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: DesignTokens.spaceMd),
              Container(
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
                        _submitError!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spaceLg),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.loginCreateAccount),
            ),
          ],
        ),
      ),
    );
  }
}
