import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/widgets/logo_mark.dart';

import '../../helpers/precache_logo.dart';

/// Mark merek: aset nyata (bukan ikon Material) dan label semantik.
void main() {
  group('LogoMark', () {
    testWidgets('aset logo benar-benar terdekode dan dirender bulat', (
      tester,
    ) async {
      await precacheLogoMark(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: LogoMark(size: 56))),
        ),
      );
      await tester.pump();

      // Bukti aset termuat: `Image` membangun `RawImage` dengan gambar nyata.
      // Bila ini null, golden akan menunjukkan lingkaran kosong dan regresi
      // visual apa pun pada logo jadi tidak terdeteksi.
      final raw = tester.widget<RawImage>(find.byType(RawImage));
      expect(raw.image, isNotNull, reason: 'aset logo harus terdekode');
      expect(raw.image!.width, 512);
      expect(raw.image!.height, 512);

      expect(tester.getSize(find.byType(LogoMark)), const Size(56, 56));
      expect(tester.takeException(), isNull);
    });

    testWidgets('label semantik dipasang hanya bila diminta', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              LogoMark(size: 56, semanticsLabel: 'Logo SIGAP-NETRA'),
              LogoMark(size: 56),
            ],
          ),
        ),
      );

      // Satu node bernama; mark dekoratif tidak menambah kebisingan
      // bagi pembaca layar.
      expect(find.bySemanticsLabel('Logo SIGAP-NETRA'), findsOneWidget);
      expect(tester.getSemantics(find.byType(LogoMark).last).label, isEmpty);

      handle.dispose();
    });
  });
}
