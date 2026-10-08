import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../devices/domain/entities/device.dart';
import 'device_connectivity_display.dart';

/// Kartu perangkat untuk daftar di Beranda dan layar Perangkat.
///
/// Widget murni tampilan: seluruh data datang dari [Device] yang sudah
/// dihitung domain-nya, sehingga tidak ada Firestore di file ini.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    required this.device,
    required this.now,
    super.key,
    this.onTap,
    this.trailing,
  });

  final Device device;
  final DateTime now;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final palette = StatusColors.of(context);
    final pillData = device.connectivity.toPillData(l10n);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Row(
            children: [
              Container(
                width: DesignTokens.deviceAvatarSize,
                height: DesignTokens.deviceAvatarSize,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusButton,
                  ),
                ),
                child: Icon(
                  Icons.visibility_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: DesignTokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      device.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: device.connectivity.solidColor(palette),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceSm),
                        Expanded(
                          child: Text(
                            '${pillData.label} - ${RelativeTime.format(device.lastSeen, now, l10n: l10n)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
