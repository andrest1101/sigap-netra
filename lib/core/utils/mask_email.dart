/// Menampilkan email dalam bentuk tersamar.
///
/// Privasi: UI tidak pernah menampilkan alamat penuh.
String maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
    return email;
  }

  final local = parts.first;
  final domain = parts.last;
  final visible = local.length <= 2 ? local : local.substring(0, 2);
  return '$visible***@$domain';
}
