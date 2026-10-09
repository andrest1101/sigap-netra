import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/constants/demo_ids.dart';
import 'package:sigap_netra_app/features/commands/data/datasources/fake_command_data_source.dart';
import 'package:sigap_netra_app/features/commands/domain/entities/device_command.dart';

void main() {
  late FakeCommandDataSource source;

  setUp(() => source = FakeCommandDataSource());
  tearDown(() => source.dispose());

  group('FakeCommandDataSource', () {
    test('sendCommand membuat pending dan mengembalikan id', () async {
      final id = await source.sendCommand(
        deviceId: kDemoDeviceId,
        type: CommandType.syncNow,
        payload: const {},
        requestedBy: kDemoUserId,
      );

      expect(id, isNotEmpty);
      final command = await source
          .watchCommand(deviceId: kDemoDeviceId, commandId: id)
          .first;
      expect(command, isNotNull);
      expect(command!.status, CommandStatus.pending);
      expect(command.requestedBy, kDemoUserId);
    });

    test('perintah tak dikenal menghasilkan null', () async {
      final command = await source
          .watchCommand(deviceId: kDemoDeviceId, commandId: 'tidak-ada')
          .first;

      expect(command, isNull);
    });

    test('device asing tidak melihat perintah demo', () async {
      final commands = await source.watchCommands(deviceId: 'dev-asing').first;

      expect(commands, isEmpty);
    });

    test('daftar awal berisi dua contoh', () async {
      final commands = await source
          .watchCommands(deviceId: kDemoDeviceId)
          .first;

      expect(commands, hasLength(2));
    });
  });
}
