import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/monitoring/data/models/detection_model.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';

void main() {
  const deviceId = 'dev-1';
  const deviceName = 'Kacamata Kamar';
  final createdAt = DateTime(2026, 10, 8, 12);

  Detection map(Map<String, dynamic> data) {
    return DetectionModel.fromData(
      data: data,
      id: 'det-1',
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }

  group('pemetaan tipe dan status', () {
    test('money + pending default bila field hilang', () {
      final detection = map({'createdAt': Timestamp.fromDate(createdAt)});

      expect(detection.type, DetectionType.money);
      expect(detection.validationStatus, ValidationStatus.pending);
      expect(detection.createdAt, createdAt);
      expect(detection.deviceId, deviceId);
      expect(detection.deviceName, deviceName);
    });

    test('text + match dipetakan benar', () {
      final detection = map({
        'type': 'text',
        'validationStatus': 'match',
        'createdAt': Timestamp.fromDate(createdAt),
        'ocrText': 'Menu makan siang',
      });

      expect(detection.type, DetectionType.text);
      expect(detection.validationStatus, ValidationStatus.match);
      expect(detection.ocrText, 'Menu makan siang');
    });

    test('nilai enum tak dikenal jatuh ke default aman', () {
      final detection = map({
        'type': 'object',
        'validationStatus': 'auto',
        'createdAt': Timestamp.fromDate(createdAt),
      });

      expect(detection.type, DetectionType.money);
      expect(detection.validationStatus, ValidationStatus.pending);
    });

    test('mismatch + validatedBy dipertahankan', () {
      final detection = map({
        'validationStatus': 'mismatch',
        'validatedBy': 'user-9',
        'createdAt': Timestamp.fromDate(createdAt),
      });

      expect(detection.validationStatus, ValidationStatus.mismatch);
      expect(detection.validatedBy, 'user-9');
    });
  });

  group('pemetaan angka dan jarak', () {
    test('distanceCm null diterima', () {
      final detection = map({
        'createdAt': Timestamp.fromDate(createdAt),
        'distanceCm': null,
      });

      expect(detection.distanceCm, isNull);
    });

    test('confidence di luar 0-1 dijepit', () {
      final over = map({
        'createdAt': Timestamp.fromDate(createdAt),
        'confidence': 1.8,
      });
      final under = map({
        'createdAt': Timestamp.fromDate(createdAt),
        'confidence': -0.2,
      });

      expect(over.confidence, 1.0);
      expect(under.confidence, 0.0);
    });

    test('confidence bukan angka menjadi null', () {
      final detection = map({
        'createdAt': Timestamp.fromDate(createdAt),
        'confidence': 'tinggi',
      });

      expect(detection.confidence, isNull);
    });

    test('amount double dibulatkan ke int', () {
      final detection = map({
        'createdAt': Timestamp.fromDate(createdAt),
        'amount': 50000.0,
      });

      expect(detection.amount, 50000);
    });
  });

  group('pengaman privasi OCR', () {
    test('ocrText 500 karakter lolos utuh', () {
      final text = 'a' * 500;
      final detection = map({
        'createdAt': Timestamp.fromDate(createdAt),
        'ocrText': text,
      });

      expect(detection.ocrText, text);
    });

    test('ocrText lebih dari 500 karakter dipotong', () {
      final detection = map({
        'createdAt': Timestamp.fromDate(createdAt),
        'ocrText': 'b' * 600,
      });

      expect(detection.ocrText, hasLength(500));
    });
  });

  group('validationUpdate', () {
    test('hanya berisi tiga field validasi', () {
      final update = DetectionModel.validationUpdate(
        status: ValidationStatus.match,
        validatedBy: 'user-1',
      );

      expect(update['validationStatus'], 'match');
      expect(update['validatedBy'], 'user-1');
      expect(update.keys, contains('validatedAt'));
      expect(update.keys, hasLength(3));
    });
  });
}
