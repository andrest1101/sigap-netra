import 'package:equatable/equatable.dart';

/// Jenis perintah jarak jauh. Daftar mengikuti `docs/firestore_schema.md`
/// bagian 4.5; jangan menambah jenis di sini tanpa persetujuan firmware.
enum CommandType { syncNow, speakText, setVolume, restart, reprovision }

/// Status perintah. Transisi hanya maju satu arah dan hanya ditulis device:
/// `pending` -> `sent` -> `acked` -> `done` atau `failed`. Aplikasi tidak
/// boleh mengubah status.
enum CommandStatus { pending, sent, acked, done, failed }

/// Batas panjang teks `speak_text` sesuai usulan skema.
///
/// [PERLU KONFIRMASI] Batas final menunggu konfirmasi firmware
/// (`docs/firestore_schema.md` bagian 4.5).
const int kSpeakTextMaxLength = 200;

/// Perintah jarak jauh: dibuat app dengan status `pending`, transisi status
/// ditulis device.
class DeviceCommand extends Equatable {
  DeviceCommand({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.status,
    required this.createdAt,
    Map<String, Object?>? payload,
    this.requestedBy,
    this.updatedAt,
    this.resultNote,
  }) : payload = Map<String, Object?>.unmodifiable(payload ?? const {});

  final String id;
  final String deviceId;
  final CommandType type;
  final CommandStatus status;
  final DateTime createdAt;

  /// Isi per `type` mengikuti skema bagian 4.5:
  /// `sync_now`/`restart`/`reprovision` wajib kosong; `speak_text` berisi
  /// `text`; `set_volume` berisi `level` 0-100. Kredensial Wi-Fi tidak pernah
  /// boleh ada di sini.
  final Map<String, Object?> payload;
  final String? requestedBy;
  final DateTime? updatedAt;
  final String? resultNote;

  /// Membangun payload yang sah untuk [type], atau melempar
  /// [ArgumentError] bila argumen tidak sah.
  ///
  /// Fungsi murni di domain supaya aturan payload diuji tanpa Firestore.
  static Map<String, Object?> buildPayload(
    CommandType type, {
    String? text,
    int? level,
  }) {
    switch (type) {
      case CommandType.syncNow:
      case CommandType.restart:
      case CommandType.reprovision:
        return const <String, Object?>{};
      case CommandType.speakText:
        final value = text?.trim() ?? '';
        if (value.isEmpty) {
          throw ArgumentError('Teks speak_text tidak boleh kosong.');
        }
        final truncated = value.length > kSpeakTextMaxLength
            ? value.substring(0, kSpeakTextMaxLength)
            : value;
        return <String, Object?>{'text': truncated};
      case CommandType.setVolume:
        if (level == null) {
          throw ArgumentError('Level set_volume wajib diisi 0-100.');
        }
        if (level < 0 || level > 100) {
          throw ArgumentError('Level set_volume harus 0-100.');
        }
        return <String, Object?>{'level': level};
    }
  }

  DeviceCommand copyWith({CommandStatus? status, String? resultNote}) {
    return DeviceCommand(
      id: id,
      deviceId: deviceId,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      payload: payload,
      requestedBy: requestedBy,
      updatedAt: updatedAt,
      resultNote: resultNote,
    );
  }

  @override
  List<Object?> get props => [
    id,
    deviceId,
    type,
    status,
    createdAt,
    payload,
    requestedBy,
    updatedAt,
    resultNote,
  ];
}
