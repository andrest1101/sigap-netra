import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/back_app_bar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../core/widgets/filter_chip_row.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../commands/domain/entities/device_command.dart';
import '../../../commands/presentation/providers/commands_providers.dart';
import '../../../commands/presentation/widgets/command_tile.dart';
import '../../../devices/presentation/providers/devices_providers.dart';
import '../../domain/entities/device_event.dart';
import '../../domain/entities/event_page.dart';
import '../providers/events_providers.dart';

/// Log koneksi/sinkronisasi dan perintah perangkat — identitas visual v3.
///
/// Tab Event punya dua mode yang jujur berbeda:
/// - **Semua** (streaming realtime, 50 kejadian terbaru) + catatan batas itu;
/// - **saringan severity** (query server `getEventsPage` dengan indeks
///   `severity + createdAt` + halaman "Muat lagi"), supaya riwayat lebih tua
///   tetap terjangkau tanpa mengunduh seluruh koleksi.
///
/// Tab Perintah memakai tile bersama `CommandTile` (bahasa status sama dengan
/// layar Kontrol). Waktu absolut disediakan untuk pembaca layar.
class ConnectionLogsScreen extends ConsumerStatefulWidget {
  const ConnectionLogsScreen({this.deviceId, super.key});

  final String? deviceId;

  @override
  ConsumerState<ConnectionLogsScreen> createState() =>
      _ConnectionLogsScreenState();
}

class _ConnectionLogsScreenState extends ConsumerState<ConnectionLogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EventSeverity? _severity;

  // Mode saringan (server-side): daftar halaman terakumulasi + kursor.
  List<DeviceEvent> _pageItems = const <DeviceEvent>[];
  EventPageCursor? _nextCursor;
  bool _pageLoading = false;
  Object? _pageError;

  /// Penjaga balapan: hasil fetch lama dibuang bila saringan berubah lagi
  /// sebelum permintaan selesai.
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? get _deviceId => widget.deviceId ?? ref.read(primaryDeviceIdProvider);

  void _onSeverityChanged(EventSeverity? value) {
    if (value == _severity) return;
    setState(() {
      _severity = value;
      _pageItems = const <DeviceEvent>[];
      _nextCursor = null;
      _pageError = null;
      _pageLoading = value != null;
    });
    if (value != null) unawaited(_loadPage(reset: true));
  }

  Future<void> _loadPage({required bool reset}) async {
    final deviceId = _deviceId;
    final severity = _severity;
    if (deviceId == null || severity == null) return;
    final generation = ++_fetchGeneration;
    setState(() {
      _pageLoading = true;
      _pageError = null;
    });
    try {
      final page = await ref
          .read(getEventsPageProvider)
          .call(
            deviceId: deviceId,
            severity: severity,
            limit: kEventsPageSize,
            startAfter: reset ? null : _nextCursor,
          );
      if (!mounted || generation != _fetchGeneration) return;
      setState(() {
        _pageItems = reset ? page.items : [..._pageItems, ...page.items];
        _nextCursor = page.nextCursor;
        _pageLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _fetchGeneration) return;
      setState(() {
        _pageError = error;
        _pageLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Layar ini juga bisa dibuka tanpa konteks perangkat (dari Pengaturan).
    // Tanpa perangkat eksplisit kita jatuh ke perangkat utama: schema tidak
    // mengizinkan query lintas perangkat.
    final deviceId = widget.deviceId ?? ref.watch(primaryDeviceIdProvider);
    final eventsAsync = deviceId == null
        ? null
        : ref.watch(eventsProvider(deviceId));
    final commandsAsync = ref.watch(commandsProvider(deviceId));
    final realtimeEvents = eventsAsync?.value ?? const <DeviceEvent>[];
    final commands = commandsAsync.value ?? const <DeviceCommand>[];
    final now = DateTime.now();
    final showLatestNote =
        deviceId != null && _severity == null && realtimeEvents.isNotEmpty;

    return Scaffold(
      appBar: BackAppBar(
        title: Text(l10n.eventsTitle),
        fallbackRoute: AppRoutes.devices,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.eventsTitle),
            Tab(text: l10n.commandsTitle),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (deviceId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacePage,
                    DesignTokens.spaceMd,
                    DesignTokens.spacePage,
                    0,
                  ),
                  child: FilterChipRow<EventSeverity>(
                    selected: _severity,
                    onChanged: _onSeverityChanged,
                    options: [
                      (label: l10n.historyFilterAll, icon: null, value: null),
                      (
                        label: l10n.eventsSeverityInfo,
                        icon: Icons.info_outline_rounded,
                        value: EventSeverity.info,
                      ),
                      (
                        label: l10n.eventsSeverityWarning,
                        icon: Icons.warning_amber_rounded,
                        value: EventSeverity.warning,
                      ),
                      (
                        label: l10n.eventsSeverityError,
                        icon: Icons.error_outline_rounded,
                        value: EventSeverity.error,
                      ),
                    ],
                  ),
                ),
              if (showLatestNote)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacePage,
                    DesignTokens.spaceMd,
                    DesignTokens.spacePage,
                    0,
                  ),
                  child: Text(
                    l10n.eventsLatestNote(realtimeEvents.length),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                child: _severity == null
                    ? _AsyncLogBody<DeviceEvent>(
                        async: eventsAsync,
                        isEmpty: realtimeEvents.isEmpty,
                        emptyTitle: l10n.eventsEmptyTitle,
                        emptyBody: l10n.eventsEmptyBody,
                        emptyIcon: Icons.hub_outlined,
                        onRetry: deviceId == null
                            ? null
                            : () => ref.invalidate(eventsProvider(deviceId)),
                        builder: (context) => ListView.separated(
                          padding: const EdgeInsets.all(DesignTokens.spacePage),
                          itemCount: realtimeEvents.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: DesignTokens.spaceSm),
                          itemBuilder: (context, index) => _EventTile(
                            event: realtimeEvents[index],
                            now: now,
                          ),
                        ),
                      )
                    : _PagedEventList(
                        loading: _pageLoading && _pageItems.isEmpty,
                        error: _pageError,
                        items: _pageItems,
                        nextCursor: _nextCursor,
                        onLoadMore: () => _loadPage(reset: false),
                        onRetry: () => _loadPage(reset: true),
                        now: now,
                      ),
              ),
            ],
          ),
          _AsyncLogBody<DeviceCommand>(
            async: commandsAsync,
            isEmpty: commands.isEmpty,
            emptyTitle: l10n.commandsTitle,
            emptyBody: l10n.eventsEmptyBody,
            emptyIcon: Icons.terminal_rounded,
            onRetry: deviceId == null
                ? null
                : () => ref.invalidate(commandsProvider(deviceId)),
            builder: (context) => ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.spacePage),
              itemCount: commands.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.spaceSm),
              itemBuilder: (context, index) =>
                  CommandTile(command: commands[index], now: now),
            ),
          ),
        ],
      ),
    );
  }
}

/// Daftar event mode saringan: halaman server + "Muat lagi" + catatan habis.
class _PagedEventList extends StatelessWidget {
  const _PagedEventList({
    required this.loading,
    required this.error,
    required this.items,
    required this.nextCursor,
    required this.onLoadMore,
    required this.onRetry,
    required this.now,
  });

  final bool loading;
  final Object? error;
  final List<DeviceEvent> items;
  final EventPageCursor? nextCursor;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (error != null && items.isEmpty) {
      return ErrorView(
        message: _failureText(context, error!),
        onRetry: onRetry,
      );
    }
    if (loading && items.isEmpty) {
      return const LoadingView();
    }
    if (items.isEmpty) {
      return EmptyView(
        title: l10n.eventsEmptyTitle,
        message: l10n.eventsEmptyBody,
        icon: Icons.hub_outlined,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.spacePage),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceSm),
      itemBuilder: (context, index) {
        if (index < items.length) {
          return _EventTile(event: items[index], now: now);
        }
        return Padding(
          padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
          child: _PagedFooter(
            loading: loading,
            hasMore: nextCursor != null,
            error: error,
            onLoadMore: onLoadMore,
            onRetry: onRetry,
          ),
        );
      },
    );
  }
}

/// Footer daftar berhalaman: tombol muat lagi / spinner / catatan habis.
///
/// Gagal memuat halaman berikutnya tidak menghapus daftar yang sudah tampil —
/// hanya baris retry yang muncul di bawah.
class _PagedFooter extends StatelessWidget {
  const _PagedFooter({
    required this.loading,
    required this.hasMore,
    required this.error,
    required this.onLoadMore,
    required this.onRetry,
  });

  final bool loading;
  final bool hasMore;
  final Object? error;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (error != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: colorScheme.error),
          const SizedBox(width: DesignTokens.spaceSm),
          Flexible(
            child: Text(
              l10n.stateErrorBody,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      );
    }
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spaceMd),
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    if (hasMore) {
      return Center(
        child: TextButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.expand_more_rounded),
          label: Text(l10n.commonLoadMore),
        ),
      );
    }
    return Center(
      child: Text(
        l10n.eventsAllLoaded,
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.now});

  final DeviceEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label:
          '${_severitySpoken(event.severity, l10n)}: ${event.message}, ${RelativeTime.date(event.createdAt)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: _severityLabel(event.severity, l10n),
              tone: _severityTone(event.severity),
              isDense: true,
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.message, style: textTheme.bodyMedium),
                  Text(
                    '${RelativeTime.format(event.createdAt, now, l10n: l10n)} · ${event.type}',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _severityLabel(EventSeverity severity, AppLocalizations l10n) {
  return switch (severity) {
    EventSeverity.info => l10n.eventsSeverityInfo,
    EventSeverity.warning => l10n.eventsSeverityWarning,
    EventSeverity.error => l10n.eventsSeverityError,
  };
}

String _severitySpoken(EventSeverity severity, AppLocalizations l10n) {
  return switch (severity) {
    EventSeverity.info => l10n.eventsSeverityInfo,
    EventSeverity.warning => l10n.statusWarning,
    EventSeverity.error => l10n.statusError,
  };
}

AppStatusTone _severityTone(EventSeverity severity) {
  return switch (severity) {
    EventSeverity.info => AppStatusTone.neutral,
    EventSeverity.warning => AppStatusTone.warn,
    EventSeverity.error => AppStatusTone.bad,
  };
}

/// Body satu tab log: membedakan loading / error / kosong / data.
///
/// [async] null berarti tidak ada perangkat terpilih — tampil sebagai kosong,
/// bukan error, karena memang tidak ada yang bisa dimuat.
class _AsyncLogBody<T> extends StatelessWidget {
  const _AsyncLogBody({
    required this.async,
    required this.isEmpty,
    required this.emptyTitle,
    required this.emptyBody,
    required this.emptyIcon,
    required this.builder,
    this.onRetry,
  });

  final AsyncValue<List<T>>? async;
  final bool isEmpty;
  final String emptyTitle;
  final String emptyBody;
  final IconData emptyIcon;
  final VoidCallback? onRetry;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final value = async;
    if (value != null && value.hasError && !value.hasValue) {
      return ErrorView(
        message: _failureText(context, value.error!),
        onRetry: onRetry,
      );
    }
    if (value != null && value.isLoading && !value.hasValue) {
      return const LoadingView();
    }
    if (value == null || isEmpty) {
      return EmptyView(title: emptyTitle, message: emptyBody, icon: emptyIcon);
    }
    return builder(context);
  }
}

/// Pesan error siap tampil untuk widget mana pun di file ini.
String _failureText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is AppFailure) return failureMessage(error, l10n);
  return l10n.stateErrorBody;
}
