import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/features/validation/domain/repositories/validation_summary.dart';
import 'package:sigap_netra_app/features/validation/domain/usecases/validation_usecases.dart';
import 'package:sigap_netra_app/features/monitoring/domain/entities/detection.dart';

Detection _detection(ValidationStatus status) {
  return Detection(
    id: 'det-${status.name}',
    deviceId: 'dev-1',
    deviceName: 'Kacamata Kamar',
    type: DetectionType.money,
    createdAt: DateTime(2026, 10, 8, 12),
    validationStatus: status,
  );
}

void main() {
  group('ValidationSummary', () {
    test('accuracy null bila belum ada validasi manusia', () {
      const summary = ValidationSummary(matches: 0, mismatches: 0, pending: 5);

      expect(summary.accuracy, isNull);
      expect(summary.decided, 0);
    });

    test('accuracy = match / (match + mismatch)', () {
      const summary = ValidationSummary(matches: 3, mismatches: 1, pending: 2);

      expect(summary.accuracy, 0.75);
      expect(summary.decided, 4);
    });

    test('empty bernilai nol semua', () {
      const summary = ValidationSummary.empty();

      expect(summary.matches, 0);
      expect(summary.mismatches, 0);
      expect(summary.pending, 0);
    });
  });

  group('calculateValidationAccuracy', () {
    test('pending tidak pernah dihitung', () {
      final accuracy = calculateValidationAccuracy([
        _detection(ValidationStatus.match),
        _detection(ValidationStatus.match),
        _detection(ValidationStatus.mismatch),
        _detection(ValidationStatus.pending),
        _detection(ValidationStatus.pending),
      ]);

      expect(accuracy, closeTo(2 / 3, 1e-9));
    });

    test('kosong menghasilkan NaN', () {
      expect(calculateValidationAccuracy(const []), isNaN);
    });
  });
}
