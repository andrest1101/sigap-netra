import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/lens_ring.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Layar QR Wi-Fi — identitas visual v3.
///
/// Stepper 3 langkah: Jaringan (Hotspot/Wi-Fi rumah + SSID/password) →
/// Tampilkan QR (panel putih, hitam di atas putih bahkan di mode gelap) →
/// Menunggu alat (Lens Ring fokus + hitung mundur 2 menit).
///
/// Format payload QR masih menunggu ekstraksi dari aplikasi Kotlin lama, jadi
/// langkah QR hanya menampilkan shell + status konfirmasi, tanpa membuat
/// payload baru.
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

  int _step = 0;
  bool _useHotspot = true;
  bool _rememberSsid = false;
  bool _obscurePassword = true;
  int _countdown = 120;
  Timer? _timer;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _countdown = _countdown > 0 ? _countdown - 1 : 0);
      if (_countdown == 0) timer.cancel();
    });
  }

  void _nextFromNetwork() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.provisioningTitle),
        fallbackRoute: AppRoutes.devices,
      ),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (index) {
          if (index < _step) setState(() => _step = index);
        },
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: Text(l10n.provisioningStepNetwork),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: _NetworkForm(
              formKey: _formKey,
              ssidController: _ssidController,
              passwordController: _passwordController,
              useHotspot: _useHotspot,
              onModeChanged: (value) => setState(() => _useHotspot = value),
              rememberSsid: _rememberSsid,
              onRememberChanged: (value) =>
                  setState(() => _rememberSsid = value),
              obscurePassword: _obscurePassword,
              onObscureToggled: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onNext: _nextFromNetwork,
            ),
          ),
          Step(
            title: Text(l10n.provisioningStepQr),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: _QrShell(
              onNext: () {
                setState(() => _step = 2);
                _startCountdown();
              },
              onBack: () => setState(() => _step = 0),
            ),
          ),
          Step(
            title: Text(l10n.provisioningStepWaiting),
            isActive: _step >= 2,
            state: StepState.indexed,
            content: _WaitingStep(
              countdown: _countdown,
              onBack: () {
                _timer?.cancel();
                setState(() => _step = 1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkForm extends StatelessWidget {
  const _NetworkForm({
    required this.formKey,
    required this.ssidController,
    required this.passwordController,
    required this.useHotspot,
    required this.onModeChanged,
    required this.rememberSsid,
    required this.onRememberChanged,
    required this.obscurePassword,
    required this.onObscureToggled,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final bool useHotspot;
  final ValueChanged<bool> onModeChanged;
  final bool rememberSsid;
  final ValueChanged<bool> onRememberChanged;
  final bool obscurePassword;
  final VoidCallback onObscureToggled;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(l10n.provisioningHotspot),
                  icon: const Icon(Icons.smartphone_outlined, size: 18),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(l10n.provisioningHomeWifi),
                  icon: const Icon(Icons.home_outlined, size: 18),
                ),
              ],
              selected: {useHotspot},
              onSelectionChanged: (selected) => onModeChanged(selected.single),
              showSelectedIcon: false,
              style: const ButtonStyle(
                shape: WidgetStatePropertyAll(StadiumBorder()),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          TextFormField(
            controller: ssidController,
            decoration: InputDecoration(
              labelText: l10n.provisioningSsidLabel,
              prefixIcon: const Icon(Icons.wifi_rounded),
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
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: l10n.provisioningPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: onObscureToggled,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: l10n.provisioningShowPassword,
              ),
            ),
            validator: (value) {
              if (value == null || value.length < kMinWifiPasswordLength) {
                return l10n.provisioningPasswordTooShort;
              }
              return null;
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.provisioningRememberSsid),
            subtitle: Text(l10n.provisioningPasswordNotStored),
            value: rememberSsid,
            onChanged: (value) => onRememberChanged(value ?? false),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          FilledButton(onPressed: onNext, child: Text(l10n.commonNext)),
        ],
      ),
    );
  }
}

/// Panel QR shell: hitam di atas putih SELALU (termasuk mode gelap) agar
/// terbaca kamera. Payload menunggu format aplikasi lama.
class _QrShell extends StatelessWidget {
  const _QrShell({required this.onNext, required this.onBack});

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacePage),
          decoration: BoxDecoration(
            // Putih selalu — bukan warna skema — supaya kamera membaca QR.
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                size: 120,
                color: Colors.black,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                kWifiQrPayloadStatusUnconfirmed,
                style: textTheme.bodySmall?.copyWith(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          l10n.provisioningPasswordNotStored,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: Text(l10n.commonBack),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: FilledButton(
                onPressed: onNext,
                child: Text(l10n.commonNext),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Langkah menunggu: Lens Ring fokus + hitung mundur 2 menit.
class _WaitingStep extends StatelessWidget {
  const _WaitingStep({required this.countdown, required this.onBack});

  final int countdown;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        LensRing(
          diameter: 120,
          mode: LensRingMode.focusing,
          semanticsLabel: l10n.provisioningWaiting,
          center: Text(
            '$countdown',
            style: textTheme.headlineSmall?.copyWith(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Text(
          l10n.provisioningCountdown(countdown),
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          l10n.provisioningWaiting,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        OutlinedButton(onPressed: onBack, child: Text(l10n.commonBack)),
      ],
    );
  }
}
