import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/retry_policy.dart';
import '../../domain/entities/device_command.dart';
import '../../domain/repositories/command_repository.dart';
import '../../domain/usecases/command_usecases.dart';

/// Sumber data perintah aktif.
///
/// Di-override di `main.dart`: `CommandRepositoryImpl` untuk Firebase, atau
/// `FakeCommandRepositoryImpl` saat mode pengembang aktif.
final commandRepositoryProvider = Provider<CommandRepository>(
  (ref) => throw UnimplementedError(
    'commandRepositoryProvider harus di-override di main.dart atau test.',
  ),
);

final watchCommandsProvider = Provider<WatchCommands>(
  (ref) => WatchCommands(ref.watch(commandRepositoryProvider)),
);

final sendCommandProvider = Provider<SendCommand>(
  (ref) => SendCommand(ref.watch(commandRepositoryProvider)),
);

/// Perintah terbaru satu perangkat, terbaru dulu.
///
/// `deviceId` null (tidak ada perangkat terpilih) mengembalikan daftar kosong:
/// schema tidak mengizinkan query lintas perangkat.
final commandsProvider = StreamProvider.autoDispose
    .family<List<DeviceCommand>, String?>((ref, deviceId) {
      if (deviceId == null) {
        return Stream<List<DeviceCommand>>.value(const <DeviceCommand>[]);
      }
      return ref.watch(watchCommandsProvider).call(deviceId: deviceId);
    }, retry: noRetry);
