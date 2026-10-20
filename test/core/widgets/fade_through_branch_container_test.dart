import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigap_netra_app/core/widgets/fade_through_branch_container.dart';

void main() {
  testWidgets('perpindahan cabang mempertahankan cabang asal selama fade', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: FadeThroughBranchContainer(
              currentIndex: index,
              children: const [Text('Beranda'), Text('Riwayat')],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => setState(() => index = 1),
              child: const Icon(Icons.navigate_next),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.navigate_next));
    await tester.pump();
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Beranda'), findsNothing);
    expect(find.text('Riwayat'), findsOneWidget);
  });

  testWidgets('preferensi kurangi animasi mengganti cabang tanpa fade', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: FadeThroughBranchContainer(
                currentIndex: index,
                children: const [Text('Beranda'), Text('Riwayat')],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => index = 1),
                child: const Icon(Icons.navigate_next),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.navigate_next));
    await tester.pump();
    expect(find.text('Beranda'), findsNothing);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
