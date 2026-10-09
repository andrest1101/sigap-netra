import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/commands/data/models/device_command_model.dart';
import 'package:sigap_netra_app/features/commands/domain/entities/device_command.dart';

void main() {
  group('buildPayload', () {
    test('sync_now, restart, reprovision wajib kosong', () {
      expect(DeviceCommand.buildPayload(CommandType.syncNow), isEmpty);
      expect(DeviceCommand.buildPayload(CommandType.restart), isEmpty);
      expect(DeviceCommand.buildPayload(CommandType.reprovision), isEmpty);
    });

    test('speak_text memakai teks dan dipotong 200 karakter', () {
      final payload = DeviceCommand.buildPayload(
        CommandType.speakText,
        text: ' Halo ',
      );
      expect(payload, {'text': 'Halo'});

      final long = DeviceCommand.buildPayload(
        CommandType.speakText,
        text: 'x' * 250,
      );
      expect((long['text'] as String), hasLength(kSpeakTextMaxLength));
    });

    test('speak_text kosong ditolak', () {
      expect(
        () => DeviceCommand.buildPayload(CommandType.speakText, text: '  '),
        throwsArgumentError,
      );
      expect(
        () => DeviceCommand.buildPayload(CommandType.speakText),
        throwsArgumentError,
      );
    });

    test('set_volume menerima 0-100 dan menolak di luar rentang', () {
      expect(DeviceCommand.buildPayload(CommandType.setVolume, level: 70), {
        'level': 70,
      });
      expect(
        () => DeviceCommand.buildPayload(CommandType.setVolume, level: -1),
        throwsArgumentError,
      );
      expect(
        () => DeviceCommand.buildPayload(CommandType.setVolume, level: 101),
        throwsArgumentError,
      );
      expect(
        () => DeviceCommand.buildPayload(CommandType.setVolume),
        throwsArgumentError,
      );
    });
  });

  group('DeviceCommandModel', () {
    test('createDocument selalu pending dengan server timestamp', () {
      final doc = DeviceCommandModel.createDocument(
        type: CommandType.syncNow,
        payload: const {},
        requestedBy: 'user-1',
      );

      expect(doc['type'], 'sync_now');
      expect(doc['status'], 'pending');
      expect(doc['requestedBy'], 'user-1');
      expect(doc['payload'], isEmpty);
      expect(doc.keys, contains('createdAt'));
    });

    test('tipe tak dikenal jatuh ke syncNow', () {
      final command = DeviceCommandModel.fromData(
        data: {'type': 'self_destruct', 'status': 'pending'},
        id: 'cmd-1',
        deviceId: 'dev-1',
      );

      expect(command.type, CommandType.syncNow);
      expect(command.status, CommandStatus.pending);
    });

    test('status tak dikenal jatuh ke pending', () {
      final command = DeviceCommandModel.fromData(
        data: {'type': 'restart', 'status': 'flying'},
        id: 'cmd-1',
        deviceId: 'dev-1',
      );

      expect(command.status, CommandStatus.pending);
    });

    test('payload non-map menjadi kosong', () {
      final command = DeviceCommandModel.fromData(
        data: {'type': 'restart', 'status': 'done', 'payload': 'kacau'},
        id: 'cmd-1',
        deviceId: 'dev-1',
      );

      expect(command.payload, isEmpty);
    });
  });
}
