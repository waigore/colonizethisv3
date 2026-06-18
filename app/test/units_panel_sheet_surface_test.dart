// Widget tests for the shared bottom-sheet host chrome used by the three
// unit panels (Civilian UNIT10001, Military UNIT20001, Naval UNIT30001).
//
// Pins the mockup `.sheet` treatment painted by [UnitsPanelSheetSurface]:
// a `surface -> bgDeep` gradient background, a 2 dp `--accent-dim` top
// edge, and a 4 dp top corner radius (bottom radii 0). These mirror the
// per-panel HTML mockup rule
// `.sheet { background: linear-gradient(180deg, var(--surface) 0%,
//   var(--bg-deep) 100%); border-top: 2px solid var(--accent-dim);
//   border-radius: 4px 4px 0 0 }`.
//
// SPEC: SPEC/ui/components/units-panel-sheet-surface.md.
// Refs #3514 (owner decision #4).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_sheet_surface.dart';

/// Resolves the [BoxDecoration] painted by the [UnitsPanelSheetSurface]
/// `DecoratedBox` that directly wraps the surface child.
BoxDecoration _surfaceDecoration(WidgetTester tester) {
  final Finder decorated = find.descendant(
    of: find.byType(UnitsPanelSheetSurface),
    matching: find.byType(DecoratedBox),
  );
  expect(
    decorated,
    findsOneWidget,
    reason:
        'UnitsPanelSheetSurface must paint exactly one DecoratedBox frame '
        'so the bottom-sheet host chrome is unambiguous.',
  );
  final DecoratedBox box = tester.widget<DecoratedBox>(decorated);
  expect(box.decoration, isA<BoxDecoration>());
  return box.decoration as BoxDecoration;
}

Future<void> _pumpSurface(WidgetTester tester, {Key? childKey}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UnitsPanelSheetSurface(
          child: SizedBox(
            key: childKey,
            width: 100,
            height: 100,
            child: const Text('panel body'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('UnitsPanelSheetSurface (#3514 bottom-sheet host chrome)', () {
    testWidgets(
      'paints a 2 dp accent-dim top edge (BorderSide width == topEdgeWidth)',
      (WidgetTester tester) async {
        await _pumpSurface(tester);

        final BoxDecoration decoration = _surfaceDecoration(tester);
        final Border? border = decoration.border as Border?;
        expect(border, isNotNull);
        expect(border!.top.width, UnitsPanelSheetSurface.topEdgeWidth);
        expect(border.top.width, 2.0);
        expect(border.top.color, EditorialMonoclePalette.accentDim);
        // Only the top edge is painted (matching `border-top: 2px ...`).
        expect(border.bottom, BorderSide.none);
        expect(border.left, BorderSide.none);
        expect(border.right, BorderSide.none);
      },
    );

    testWidgets(
      'rounds only the top corners by 4 dp (border-radius: 4px 4px 0 0)',
      (WidgetTester tester) async {
        await _pumpSurface(tester);

        final BoxDecoration decoration = _surfaceDecoration(tester);
        final BorderRadius radius = decoration.borderRadius! as BorderRadius;
        expect(
          radius.topLeft.x,
          UnitsPanelSheetSurface.topCornerRadius,
        );
        expect(radius.topLeft.x, 4.0);
        expect(radius.topRight.x, 4.0);
        expect(radius.bottomLeft.x, 0.0);
        expect(radius.bottomRight.x, 0.0);
      },
    );

    testWidgets(
      'fills with the surface -> bgDeep vertical gradient',
      (WidgetTester tester) async {
        await _pumpSurface(tester);

        final BoxDecoration decoration = _surfaceDecoration(tester);
        final LinearGradient gradient = decoration.gradient! as LinearGradient;
        expect(gradient.colors, <Color>[
          EditorialMonoclePalette.surface,
          EditorialMonoclePalette.bgDeep,
        ]);
        expect(gradient.begin, Alignment.topCenter);
        expect(gradient.end, Alignment.bottomCenter);
      },
    );

    testWidgets(
      'is a pure wrapper that keeps the child reachable',
      (WidgetTester tester) async {
        const Key childKey = Key('sheet-child');
        await _pumpSurface(tester, childKey: childKey);

        expect(find.byKey(childKey), findsOneWidget);
        expect(find.text('panel body'), findsOneWidget);
      },
    );
  });
}
