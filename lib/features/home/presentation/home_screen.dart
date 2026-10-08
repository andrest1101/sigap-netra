import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../features/devices/domain/entities/device.dart';
import '../../../../features/devices/presentation/providers/devices_providers.dart';
import '../../../../features/devices/presentation/widgets/device_card.dart';

/// Layar Beranda.
///
/// Ferry komposisi murni: menyatukan daftar perangkat, ringkasan validasi, dan
/// aktivitas terbaru. Tidak ada query Firestore di file ini, semuanya lewat
/// provider.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final devices = ref.watch(myDevicesProvider);
    final now = DateTime.now();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: l10n.homeTitle,
            subtitle: l10n.appSubtitle,
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(myDevicesProvider),
                icon: const Icon(Icons.refresh),
                tooltip: l10n.commonRefresh,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
          Expanded(
            child: devices.when(
              loading: () => const SkeletonList(itemCount: 3),
              error: (error, _) => ErrorView(
                message: _messageFor(context, error),
                onRetry: () => ref.invalidate(myDevicesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyView(
                    title: l10n.homeNoDevicesTitle,
                    message: l10n.homeNoDevicesBody,
                    icon: Icons.devices_other_outlined,
                    action: FilledButton.icon(
                      onPressed: () => const DevicesPath().go(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.deviceAdd),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myDevicesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceMd),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _HomeSummary(devices: list, now: now);
                      }
                      final device = list[index - 1];
                      return DeviceCard(
                        device: device,
                        now: now,
                        onTap: () =>
                            DeviceDetailPath(device.deviceId).go(context),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _messageFor(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context);
    if (error is AppFailure) return error.message(l10n);
    return l10n.stateErrorBody;
  }
}

/// Ringkasan singkat di atas Beranda.
class _HomeSummary extends StatelessWidget {
  const _HomeSummary({required this.devices, required this.now});

  final List<Device> devices;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onlineCount = devices
        .where((device) => device.connectivity == DeviceConnectivity.online)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.homeValidationSummary,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Row(
              children: [
                _SummaryTile(
                  label: l10n.statusOnline,
                  value: '$onlineCount / ${devices.length}',
                  color: colorScheme.primary,
                ),
                const SizedBox(width: DesignTokens.spaceLg),
                Expanded(
                  child: _SummaryTile(
                    label: l10n.homeLastSeenLabel,
                    value: RelativeTime.format(
                      devices.first.lastSeen,
                      now,
                      l10n: l10n,
                    ),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
