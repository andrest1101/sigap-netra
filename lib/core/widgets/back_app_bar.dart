import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AppBar untuk layar anak: tombol kembali eksplisit + fallback aman.
///
/// Aturan navigasi: layar anak selalu dibuka via `push()` sehingga panah back
/// muncul otomatis. Bila layar dibuka langsung (deep-link, stack kosong),
/// `context.canPop()` false dan tombol kembali memakai [fallbackRoute]
/// (mis. `/perangkat`) — pengguna tidak pernah terlempar keluar aplikasi.
///
/// Jangan mengandalkan back otomatis AppBar tanpa widget ini: satu-satunya
/// entry yang salah (`go()` alih-alih `push()`) sudah cukup menghapus panah
/// back tanpa peringatan compile-time.
class BackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BackAppBar({
    required this.title,
    required this.fallbackRoute,
    super.key,
    this.actions = const [],
    this.bottom,
  });

  final Widget title;
  final String fallbackRoute;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      bottom: bottom,
      leading: BackButton(onPressed: () => _goBack(context)),
    );
  }
}
