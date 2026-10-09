import '../../domain/entities/share_report.dart';
import '../../domain/repositories/share_repository.dart';
import '../datasources/share_data_source.dart';

/// Implementasi [ShareRepository] di atas kontrak [ShareDataSource].
class ShareRepositoryImpl implements ShareRepository {
  ShareRepositoryImpl(this._dataSource);

  final ShareDataSource _dataSource;

  @override
  Future<void> shareReport(ShareReport report) {
    return _dataSource.shareReport(report);
  }
}
