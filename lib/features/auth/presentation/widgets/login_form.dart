import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Formulir masuk.
///
/// Terpisah dari `LoginScreen` supaya widget ini murni tampilan: semua string
/// dari l10n, semua aksi lewat callback, tidak ada akses ke Firebase.
class LoginForm extends StatelessWidget {
  const LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.onSubmitEmail,
    super.key,
    this.onSubmitGoogle,
    this.isEmailSubmitting = false,
    this.isGoogleSubmitting = false,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;

  /// Null ketika sedang mengirim, dipakai untuk menonaktifkan tombol.
  final VoidCallback? onSubmitEmail;
  final VoidCallback? onSubmitGoogle;

  final bool isEmailSubmitting;
  final bool isGoogleSubmitting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailController,
            enabled: !isEmailSubmitting,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.loginEmailLabel,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          TextField(
            controller: passwordController,
            enabled: !isEmailSubmitting,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onSubmitEmail?.call(),
            decoration: InputDecoration(
              labelText: l10n.loginPasswordLabel,
              helperText: l10n.loginPasswordHint,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceXl),
          FilledButton(
            onPressed: onSubmitEmail,
            child: isEmailSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.loginSignInWithEmail),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          OutlinedButton.icon(
            onPressed: onSubmitGoogle,
            icon: isGoogleSubmitting
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
        ],
      ),
    );
  }
}
