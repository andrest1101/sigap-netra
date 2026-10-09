import 'package:equatable/equatable.dart';

import '../../../monitoring/domain/entities/detection.dart';

/// Kursor halaman riwayat yang bebas Firestore.
///
/// Domain tidak boleh mengimpor `DocumentSnapshot`, jadi kursor memakai nilai
/// field `createdAt` + `id` item terakhir. Data layer Firestore memakainya
/// lewat `startAfter([createdAt])` pada query `orderBy createdAt DESC`.
class DetectionPageCursor extends Equatable {
  const DetectionPageCursor({required this.createdAt, required this.id});

  /// Dibangun dari item terakhir halaman sebelumnya.
  factory DetectionPageCursor.fromDetection(Detection detection) {
    return DetectionPageCursor(
      createdAt: detection.createdAt,
      id: detection.id,
    );
  }

  final DateTime createdAt;
  final String id;

  @override
  List<Object?> get props => [createdAt, id];
}

/// Satu halaman riwayat beserta kursor halaman berikutnya.
///
/// [nextCursor] null berarti tidak ada halaman lagi.
class DetectionPage extends Equatable {
  const DetectionPage({required this.items, this.nextCursor});

  final List<Detection> items;
  final DetectionPageCursor? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
