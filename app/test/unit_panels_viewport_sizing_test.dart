// Viewport-adaptive bottom-sheet sizing for the three unit panels
// (Civilian UNIT10001, Military UNIT20001, Naval UNIT30001).
//
// Covers the shared `unitsPanelSheetConstraints` contract from
// SPEC/ui/components/units-panel-shell.md § Bottom-sheet sizing:
//   - narrow (`width < kNarrowBreakpoint`): full width × 50% height
//   - wide   (`width >= kNarrowBreakpoint`): 70% width × 55vh
// plus the `600` dp boundary flip, and a widget assertion that the shell now
// expands beyond the legacy fixed `400` dp width inside a wide host (the width
// is host-governed, not pinned by the shell). Refs #3627.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_viewport_constraints.dart';

void main() {
  suppressLogsForTests();

  group('unitsPanelSheetConstraints (Refs #3627)', () {
    test('AC1 (narrow): full width and 50% height below kNarrowBreakpoint', () {
      const Size viewport = Size(360, 640);
      final BoxConstraints c = unitsPanelSheetConstraints(viewport);
      expect(c.maxWidth, closeTo(360, 0.01));
      expect(c.maxHeight, closeTo(320, 0.01)); // 640 * 0.50
    });

    test('AC1 (narrow @ 320×640 minimum viewport)', () {
      final BoxConstraints c = unitsPanelSheetConstraints(
        const Size(kMinViewportWidth, 640),
      );
      expect(c.maxWidth, closeTo(320, 0.01));
      expect(c.maxHeight, closeTo(320, 0.01));
    });

    test('AC2 (wide): 70% width and 55vh at and above kNarrowBreakpoint', () {
      const Size viewport = Size(1024, 768);
      final BoxConstraints c = unitsPanelSheetConstraints(viewport);
      expect(c.maxWidth, closeTo(716.8, 0.01)); // 1024 * 0.70
      expect(c.maxHeight, closeTo(422.4, 0.01)); // 768 * 0.55
    });

    test('AC2 (wide tall): factors scale with a tall desktop viewport', () {
      const Size viewport = Size(1440, 1080);
      final BoxConstraints c = unitsPanelSheetConstraints(viewport);
      expect(c.maxWidth, closeTo(1008, 0.01)); // 1440 * 0.70
      expect(c.maxHeight, closeTo(594, 0.01)); // 1080 * 0.55
    });

    test('boundary: exactly kNarrowBreakpoint (600) uses the WIDE rule', () {
      final BoxConstraints c = unitsPanelSheetConstraints(
        const Size(kNarrowBreakpoint, 800),
      );
      expect(c.maxWidth, closeTo(600 * 0.70, 0.01)); // 420
      expect(c.maxHeight, closeTo(800 * 0.55, 0.01)); // 440
    });

    test('boundary (negative): just below 600 uses the NARROW rule', () {
      final BoxConstraints c = unitsPanelSheetConstraints(
        const Size(kNarrowBreakpoint - 1, 800),
      );
      // Narrow → full width (not 70%) and 50% height (not 55%).
      expect(c.maxWidth, closeTo(599, 0.01));
      expect(c.maxHeight, closeTo(400, 0.01)); // 800 * 0.50
      // Guard against silently applying the wide rule at the boundary.
      expect(c.maxWidth, isNot(closeTo(599 * 0.70, 0.01)));
      expect(c.maxHeight, isNot(closeTo(800 * 0.55, 0.01)));
    });

    test('sizing factor constants match the SPEC contract', () {
      expect(kUnitsPanelNarrowHeightFactor, 0.50);
      expect(kUnitsPanelWideWidthFactor, 0.70);
      expect(kUnitsPanelWideHeightFactor, 0.55);
    });
  });

  group('UnitsPanelShell host-governed width (Refs #3627)', () {
    test('defaultPanelConstraints leaves width unbounded with a 500 cap', () {
      expect(
        UnitsPanelShell.defaultPanelConstraints.maxWidth,
        double.infinity,
        reason:
            'The bottom-sheet host owns the panel width via '
            'unitsPanelSheetConstraints; the shell must not pin a fixed width.',
      );
      expect(UnitsPanelShell.defaultPanelConstraints.maxHeight, 500);
    });

    testWidgets('expands beyond the legacy 400 dp width inside a wide host', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 700,
                child: UnitsPanelShell(
                  title: 'Civilian Units',
                  hasContent: false,
                  listChildren: <Widget>[],
                  emptyMessage: 'No civilian units',
                ),
              ),
            ),
          ),
        ),
      );

      final double shellWidth = tester
          .getSize(find.byType(UnitsPanelShell))
          .width;
      expect(
        shellWidth,
        greaterThan(400),
        reason:
            'With width host-governed (default constraints unbounded), the '
            'shell fills the 700 dp host instead of the stale 400 dp cap.',
      );
      expect(shellWidth, closeTo(700, 0.5));
      expect(find.text('Civilian Units'), findsOneWidget);
    });
  });
}
