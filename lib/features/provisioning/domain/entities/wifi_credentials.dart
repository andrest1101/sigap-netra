import 'package:equatable/equatable.dart';

/// Kredensial Wi-Fi dari form lokal.
///
/// Kata sandi tidak pernah disimpan di aplikasi dan tidak pernah ditulis ke
/// Firestore. Objek ini hanya hidup selama proses provisioning.
class WifiCredentials extends Equatable {
  const WifiCredentials({required this.ssid, required this.password});

  final String ssid;
  final String password;

  @override
  List<Object?> get props => [ssid, password];
}
