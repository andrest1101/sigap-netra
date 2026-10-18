import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/lens_ring.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../domain/entities/wifi_credentials.dart';
import '../../domain/usecases/build_wifi_qr_payload.dart';

/// Layar QR Wi-Fi — identitas visual v3.
///
/// Stepper 3 langkah: Jaringan (Hotspot/Wi-Fi rumah + SSID/password) →
/// Tampilkan QR (panel putih, hitam di atas putih agar selalu terbaca kamera
/// alat) → Menunggu alat.
///
/// Langkah 3 punya tiga keadaan yang jujur:
/// - **menunggu** — Lens Ring fokus + hitung mundur 2 menit;
/// - **terhubung** — `lastSeen` perangkat bergerak maju melewati patokan saat
///   langkah ini dibuka (bukti detak baru, bukan klaim kosong);
/// - **belum tersambung** — hitung mundur habis tanpa detak baru, dengan
///   tombol "Coba lagi" yang mengambil patokan ulang.
///
/// [PERLU KONFIRMASI] Apakah firmware memperbarui `wifiSsid` secara andal saat
/// reprovision: begitu dikonfirmasi, kecocokan SSID bisa dijadikan syarat
/// tambahan selain detak baru (lihat `progress.md`).
///
/// Payload QR memakai format aplikasi Kotlin lama
/// (`WIFI:T:WPA;S:<ssid>;P:<sandi>;;`, lihat `buildWifiQrPayload`), tetapi
/// firmware MaixCAM belum memindai QR — catatan status jujur ditampilkan di
/// bawah kode.
class WifiProvisioningScreen extends ConsumerStatefulWidget {
  const WifiProvisioningScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  ConsumerState<WifiProvisioningScreen> createState() =>
      _WifiProvisioningScreenState();
}

class _WifiProvisioningScreenState
    extends ConsumerState<WifiProvisioningScreen> {
  static const int _countdownSeconds = 120;

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _step = 0;
  bool _useHotspot = true;
  bool _rememberSsid = false;
  bool _obscurePassword = true;
  int _countdown = _countdownSeconds;
  Timer? _timer;

  /// `lastSeen` saat langkah menunggu dibuka; detak yang lebih baru dari ini
  /// adalah bukti alat benar-benar hidup setelah pemindaian.
  DateTime? _baselineLastSeen;
  bool _connected = false;
  bool _timedOut = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _countdownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _countdown = _countdown > 0 ? _countdown - 1 : 0;
        if (_countdown == 0 && !_connected) _timedOut = true;
      });
      if (_countdown == 0) timer.cancel();
    });
  }

  DateTime? _currentLastSeen() {
    return ref.read(deviceProvider(widget.deviceId)).value?.lastSeen;
  }

  void _enterWaiting() {
    _baselineLastSeen = _currentLastSeen();
    _connected = false;
    _timedOut = false;
    setState(() => _step = 2);
    _startCountdown();
  }

  void _retryWaiting() {
    _baselineLastSeen = _currentLastSeen();
    setState(() {
      _connected = false;
      _timedOut = false;
    });
    _startCountdown();
  }

  void _leaveWaiting(int step) {
    _timer?.cancel();
    setState(() {
      _step = step;
      _connected = false;
      _timedOut = false;
    });
  }

  void _nextFromNetwork() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _step = 1);
  }

  /// Payload QR dari isi form saat ini. Hanya hidup di memori selama layar
  /// terbuka; tidak pernah disimpan.
  String get _qrPayload => buildWifiQrPayload(
    WifiCredentials(
      ssid: _ssidController.text.trim(),
      password: _passwordController.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Detak pertama setelah pemindaian: `lastSeen` maju melewati patokan →
    // alat benar-benar hidup di jaringan baru. Dibaca lewat stream dokumen
    // perangkat, bukan polling.
    ref.listen(deviceProvider(widget.deviceId), (previous, next) {
      final device = next.value;
      if (device == null || _step != 2 || _connected) return;
      final baseline = _baselineLastSeen;
      if (baseline == null) {
        // Data pertama baru tiba setelah layar dibuka: jadikan patokan.
        _baselineLastSeen = device.lastSeen;
        return;
      }
      final lastSeen = device.lastSeen;
      if (lastSeen != null && lastSeen.isAfter(baseline)) {
        _timer?.cancel();
        setState(() {
          _connected = true;
          _timedOut = false;
        });
      }
    });

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.provisioningTitle),
        fallbackRoute: AppRoutes.devices,
      ),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (index) {
          if (index < _step) _leaveWaiting(index);
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
              payload: _qrPayload,
              onNext: _enterWaiting,
              onBack: () => _leaveWaiting(0),
            ),
          ),
          Step(
            title: Text(l10n.provisioningStepWaiting),
            isActive: _step >= 2,
            state: _connected ? StepState.complete : StepState.indexed,
            content: _WaitingStep(
              countdown: _countdown,
              connected: _connected,
              timedOut: _timedOut,
              onBack: () => _leaveWaiting(1),
              onRetry: _retryWaiting,
              onFinish: () => Navigator.of(context).maybePop(),
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

/// Panel QR: hitam di atas putih SELALU (bukan warna skema) agar terbaca
/// kamera. Payload memakai format aplikasi lama; firmware belum memindai QR,
/// jadi catatan status jujur ditampilkan di bawah kode.
class _QrShell extends StatelessWidget {
  const _QrShell({
    required this.payload,
    required this.onNext,
    required this.onBack,
  });

  final String payload;
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
              Semantics(
                label: l10n.provisioningStepQr,
                image: true,
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                kWifiQrPayloadNote,
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

/// Langkah menunggu alat: menunggu (fokus + hitung mundur), terhubung, atau
/// belum tersambung — tiga keadaan dengan aksi yang jelas.
class _WaitingStep extends StatelessWidget {
  const _WaitingStep({
    required this.countdown,
    required this.connected,
    required this.timedOut,
    required this.onBack,
    required this.onRetry,
    required this.onFinish,
  });

  final int countdown;
  final bool connected;
  final bool timedOut;
  final VoidCallback onBack;
  final VoidCallback onRetry;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (connected) {
      content = _ConnectedState(onFinish: onFinish);
    } else if (timedOut) {
      content = _TimedOutState(onBack: onBack, onRetry: onRetry);
    } else {
      content = _CountingState(countdown: countdown, onBack: onBack);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: content,
    );
  }
}

class _ConnectedState extends StatelessWidget {
  const _ConnectedState({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final ok = StatusColors.of(context).ok.solid;

    return Column(
      key: const ValueKey('provisioning-connected'),
      children: [
        LensRing(
          diameter: 120,
          value: 1,
          progressColor: ok,
          semanticsLabel: l10n.provisioningSuccess,
          center: Icon(Icons.check_rounded, size: 44, color: ok),
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Text(
          l10n.provisioningSuccess,
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          l10n.provisioningSuccessHint,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        FilledButton(onPressed: onFinish, child: Text(l10n.commonDone)),
      ],
    );
  }
}

class _TimedOutState extends StatelessWidget {
  const _TimedOutState({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      key: const ValueKey('provisioning-timeout'),
      children: [
        LensRing(
          diameter: 120,
          semanticsLabel: l10n.provisioningTimeoutTitle,
          unavailableIcon: Icons.wifi_off_rounded,
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Text(
          l10n.provisioningTimeoutTitle,
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          l10n.provisioningTimeoutBody,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
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
                onPressed: onRetry,
                child: Text(l10n.commonRetry),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountingState extends StatelessWidget {
  const _CountingState({required this.countdown, required this.onBack});

  final int countdown;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('provisioning-counting'),
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
