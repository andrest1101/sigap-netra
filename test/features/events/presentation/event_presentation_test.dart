import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/events/presentation/widgets/event_presentation.dart';
import 'package:sigap_netra_app/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('id'));
  });

  test('prefiks event dipetakan ke kategori manusiawi', () {
    expect(
      eventCategoryLabel('wlan_disconnected', l10n),
      l10n.eventsCategoryNetwork,
    );
    expect(
      eventCategoryLabel('wifi_connected', l10n),
      l10n.eventsCategoryNetwork,
    );
    expect(
      eventCategoryLabel('command_failed', l10n),
      l10n.eventsCategoryCommand,
    );
    expect(eventCategoryLabel('boot', l10n), l10n.eventsCategorySystem);
    expect(
      eventCategoryLabel('heartbeat_lost', l10n),
      l10n.eventsCategorySystem,
    );
    expect(
      eventCategoryLabel('config_changed', l10n),
      l10n.eventsCategorySystem,
    );
    expect(eventCategoryLabel('storage_low', l10n), l10n.eventsCategorySystem);
    expect(eventCategoryLabel('auth_failed', l10n), l10n.eventsCategorySystem);
    expect(
      eventCategoryLabel('camera_error', l10n),
      l10n.eventsCategoryReading,
    );
    expect(
      eventCategoryLabel('lidar_timeout', l10n),
      l10n.eventsCategoryReading,
    );
    expect(
      eventCategoryLabel('sensor_error', l10n),
      l10n.eventsCategoryReading,
    );
  });

  test('tipe tak dikenal atau kosong tetap punya label netral', () {
    expect(eventCategoryLabel('', l10n), l10n.eventsCategoryGeneral);
    expect(
      eventCategoryLabel('vendor_custom_event', l10n),
      l10n.eventsCategoryGeneral,
    );
  });
}
