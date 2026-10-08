import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../features/devices/domain/entities/device.dart';
import '../providers/devices_providers.dart';
import '../widgets/device_card.dart';
import '../../../../core/router/app_router.dart';

/// Layar daftar perangkat milik pengguna.
class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final devices = ref.watch(myDevicesProvider);
    final now = DateTime.now();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: l10n.devicesTitle,
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
                message: error is AppFailure ? error.message(l10n) : null,
                onRetry: () => ref.invalidate(myDevicesProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return EmptyView(
                    title: l10n.devicesEmptyTitle,
                    message: l10n.devicesEmptyBody,
                    icon: Icons.devices_other_outlined,
                    action: FilledButton.icon(
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(l10n.deviceAdd),
                      onPressed: () =>
                          context.push('${AppRoutes.devices}/new/wifi'),
                    ),
                  );
                }

                final onlineCount = list
                    .where(
                      (device) =>
                          device.connectivity == DeviceConnectivity.online,
                    )
                    .length;
                final offlineCount = list.length - onlineCount;

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myDevicesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceMd),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _DevicesSummaryBadge(
                          onlineCount: onlineCount,
                          offlineCount: offlineCount,
                        );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.devices}/new/wifi'),
        icon: const Icon(Icons.add),
        label: Text(l10n.deviceAdd),
      ),
    );
  }
}

class _DevicesSummaryBadge extends StatelessWidget {
  const _DevicesSummaryBadge({
    required this.onlineCount,
    required this.offlineCount,
  });

  final int onlineCount;
  final int offlineCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _CountChip(label: l10n.statusOnline, count: onlineCount),
        const SizedBox(width: DesignTokens.spaceSm),
        _CountChip(label: l10n.statusOffline, count: offlineCount),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $count'),
      avatar: const Icon(Icons.circle, size: 8),
    );
  }
}
