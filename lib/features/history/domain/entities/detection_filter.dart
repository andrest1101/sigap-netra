import 'package:equatable/equatable.dart';

import '../../../monitoring/domain/entities/detection.dart';

/// Filter riwayat pembacaan pada domain.
///
/// Firestore pagination dan query lengkap belum diimplementasikan karena
/// kontrak security/index lintas-perangkat masih berstatus
/// `[PERLU KONFIRMASI]`.
class DetectionFilter extends Equatable {
  const DetectionFilter({this.type, this.status, this.deviceId});

  final DetectionType? type;
  final ValidationStatus? status;
  final String? deviceId;

  DetectionFilter copyWith({
    DetectionType? type,
    ValidationStatus? status,
    String? deviceId,
  }) {
    return DetectionFilter(
      type: type ?? this.type,
      status: status ?? this.status,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  bool matches(Detection detection) {
    return (type == null || detection.type == type) &&
        (status == null || detection.validationStatus == status) &&
        (deviceId == null || detection.deviceId == deviceId);
  }

  @override
  List<Object?> get props => [type, status, deviceId];
}
