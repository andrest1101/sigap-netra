import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Layar pemasangan Wi-Fi via QR.
///
/// Format payload QR masih menunggu ekstraksi dari aplikasi Kotlin lama, jadi
/// layar ini hanya validasi form dan catatan keamanan, tanpa membuat payload
/// baru.
class WifiProvisioningScreen extends StatefulWidget {
  const WifiProvisioningScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  State<WifiProvisioningScreen> createState() => _WifiProvisioningScreenState();
}

class _WifiProvisioningScreenState extends State<WifiProvisioningScreen> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _generated = false;
  String? _inlineMessage;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _generate() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _generated = true;
      _inlineMessage = kWifiQrPayloadStatusUnconfirmed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(title: l10n.provisioningTitle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _ssidController,
                      decoration: InputDecoration(
                        labelText: l10n.provisioningSsidLabel,
                        prefixIcon: const Icon(Icons.wifi),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.provisioningInvalidSsid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: l10n.provisioningPasswordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: l10n.provisioningShowPassword,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return l10n.provisioningPasswordTooShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    FilledButton(
                      onPressed: _generate,
                      child: Text(l10n.provisioningGenerate),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    if (_generated)
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.spaceLg),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusCard,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_2, size: 96),
                            const SizedBox(height: DesignTokens.spaceMd),
                            Text(
                              l10n.provisioningWaiting,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DesignTokens.spaceSm),
                            Text(
                              _inlineMessage ??
                                  l10n.provisioningPasswordNotStored,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    Text(
                      l10n.provisioningPasswordNotStored,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
