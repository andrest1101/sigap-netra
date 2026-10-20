/// Sumber data aktif untuk seluruh aplikasi.
///
/// Domain menentukan sendiri apa yang dibutuhkan tanpa tahu sumber datanya.
enum DataSource {
  /// Cloud Firestore sungguhan.
  firebase,

  /// Data simulasi in-memory untuk pengembangan dan demo.
  simulation;

  /// Label siap tampil untuk UI Pengaturan. String akhir tetap lewat l10n;
  /// enum ini hanya menyimpan nilai yang stabil untuk logika dan pengujian.
  String get storageKey => name;
}

/// Sebab aplikasi memakai data simulasi.
///
/// Dua sebab ini punya arti berbeda bagi pengguna dan tidak boleh disatukan
/// menjadi satu kalimat "Simulasi":
/// - [developerMode]: pilihan sadar pengguna di Pengaturan;
/// - [firebaseUnavailable]: build tidak punya konfigurasi Firebase yang sah,
///   sehingga aplikasi jatuh ke simulasi agar tidak macet.
enum SimulationReason { developerMode, firebaseUnavailable }

/// Hasil resolusi sumber data: apa yang benar-benar dipakai + alasannya.
///
/// Dibuat sekali di `main.dart` dan dibagikan ke UI lewat
/// `dataSourceSelectionProvider`. UI **tidak boleh** menyimpulkan mode dari
/// preferensi saja: Firebase bisa gagal init, dan saat itu preferensi tetap
/// berbunyi "Firebase" padahal data yang tampil adalah simulasi.
class DataSourceSelection {
  const DataSourceSelection({required this.dataSource, this.simulationReason})
    : assert(
        dataSource == DataSource.simulation || simulationReason == null,
        'Sumber data Firebase tidak punya alasan simulasi.',
      ),
      assert(
        dataSource != DataSource.simulation || simulationReason != null,
        'Simulasi wajib menyebut alasannya agar UI jujur.',
      );

  /// Simulasi karena pilihan pengguna / build tanpa Firebase.
  const DataSourceSelection.simulation(SimulationReason reason)
    : this(dataSource: DataSource.simulation, simulationReason: reason);

  /// Firebase aktif dan siap.
  const DataSourceSelection.firebase() : this(dataSource: DataSource.firebase);

  final DataSource dataSource;
  final SimulationReason? simulationReason;

  bool get isSimulation => dataSource == DataSource.simulation;

  @override
  bool operator ==(Object other) =>
      other is DataSourceSelection &&
      other.dataSource == dataSource &&
      other.simulationReason == simulationReason;

  @override
  int get hashCode => Object.hash(dataSource, simulationReason);

  @override
  String toString() =>
      'DataSourceSelection(${dataSource.name}, ${simulationReason?.name})';
}
