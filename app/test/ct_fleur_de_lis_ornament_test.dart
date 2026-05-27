import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_fleur_de_lis_ornament.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpInside(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
    await tester.pump();
  }

  group('CtFleurDeLisOrnament visual contract (Refs #2860 S4)', () {
    testWidgets('honours default size (24 x 32)', (tester) async {
      await pumpInside(tester, const CtFleurDeLisOrnament());
      final Size renderedSize = tester.getSize(
        find.byType(CtFleurDeLisOrnament),
      );
      expect(renderedSize.width, 24.0);
      expect(renderedSize.height, 32.0);
    });

    testWidgets('honours custom width and height parameters', (tester) async {
      await pumpInside(
        tester,
        const CtFleurDeLisOrnament(width: 18, height: 22),
      );
      final Size renderedSize = tester.getSize(
        find.byType(CtFleurDeLisOrnament),
      );
      expect(renderedSize.width, 18.0);
      expect(renderedSize.height, 22.0);
    });

    testWidgets('uses brass `accent-dim` token from #2858 (no hard-coded hex)',
        (tester) async {
      await pumpInside(tester, const CtFleurDeLisOrnament());
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CtFleurDeLisOrnament),
          matching: find.byType(CustomPaint),
        ),
      );
      final dynamic painter = paint.painter;
      expect(painter, isNotNull);
      expect((painter as dynamic).color, EditorialMonoclePalette.accentDim);
    });

    test('glyph paints at 0.6 alpha per mockup `.title-flank { opacity }`', () {
      expect(ctFleurDeLisGlyphOpacityForTesting, closeTo(0.6, 1e-9));
    });

    test('canonical viewBox is 24 x 32 (matches inline mockup `<svg>`)', () {
      expect(ctFleurDeLisViewBoxForTesting, const Size(24, 32));
    });

    testWidgets('renders without exception at zero-degenerate sizes '
        '(negative-path guard)', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(
          width: 0,
          height: 0,
          child: CtFleurDeLisOrnament(width: 0, height: 0),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
