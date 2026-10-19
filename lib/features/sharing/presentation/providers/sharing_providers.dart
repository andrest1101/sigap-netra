import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/share_plus_data_source.dart';
import '../../data/repositories/share_repository_impl.dart';
import '../../domain/repositories/share_repository.dart';
import '../../domain/usecases/build_share_report.dart';
import '../../domain/usecases/share_csv_file.dart';

/// Sumber bagikan berbasis `share_plus`.
///
/// Tidak bergantung pada Firebase: aman di mode pengembangan maupun mode
/// Firebase. Widget test yang memicu bagikan wajib meng-override provider ini
/// dengan fake supaya plugin tidak dipanggil.
final shareRepositoryProvider = Provider<ShareRepository>(
  (ref) => ShareRepositoryImpl(SharePlusDataSource()),
);

final shareReportProvider = Provider<ShareReportUseCase>(
  (ref) => ShareReportUseCase(ref.watch(shareRepositoryProvider)),
);

/// Ekspor CSV Riwayat: berkas sementara + share sheet (bukan teks laporan).
final shareCsvProvider = Provider<ShareCsvFileUseCase>(
  (ref) => ShareCsvFileUseCase(ref.watch(shareRepositoryProvider)),
);
