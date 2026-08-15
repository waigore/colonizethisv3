// Pins MAP10001 improvement-headroom legend visibility + popover (Refs #4408).
import 'package:colonizethis_app/features/game/flame/controls/improvement_headroom_legend.dart';
import 'package:colonizethis_app/features/game/flame/controls/improvement_headroom_legend_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('shouldShowImprovementHeadroomLegend', () {
    test('shows when improvements are on with a viewing player', () {
      expect(
        shouldShowImprovementHeadroomLegend(
          flags: MapBaseLayerFlags.fullDetail,
          viewingPlayerId: 'gp_player',
        ),
        isTrue,
      );
    });

    test('hides when improvements are off', () {
      expect(
        shouldShowImprovementHeadroomLegend(
          flags: MapBaseLayerFlags.resourcesOnly,
          viewingPlayerId: 'gp_player',
        ),
        isFalse,
      );
    });

    test('hides in global observe', () {
      expect(
        shouldShowImprovementHeadroomLegend(
          flags: MapBaseLayerFlags.fullDetail,
          viewingPlayerId: null,
        ),
        isFalse,
      );
    });
  });

  group('ImprovementHeadroomLegend chrome', () {
    testWidgets('wide legend shows headroom copy without I-prefix jargon', (
      tester,
    ) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Center(
              child: ImprovementHeadroomLegend(
                key: anchor,
                narrow: false,
                anchorKey: anchor,
                chromeBottomY: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(kImprovementHeadroomLegendKey), findsOneWidget);
      expect(find.text('Can still raise'), findsOneWidget);
      expect(find.text("At this court's limit"), findsOneWidget);
      expect(find.textContaining('I1'), findsNothing);
      expect(find.textContaining('extractionCap'), findsNothing);
    });

    testWidgets('tap opens popover; close button dismisses', (tester) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Center(
              child: ImprovementHeadroomLegend(
                key: anchor,
                narrow: false,
                anchorKey: anchor,
                chromeBottomY: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(kImprovementHeadroomLegendKey));
      await tester.pumpAndSettle();

      expect(find.byKey(kImprovementHeadroomLegendPanelKey), findsOneWidget);
      expect(
        find.textContaining('improvement level versus what this court'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(ImprovementHeadroomLegendPanel.closeButtonKey),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(kImprovementHeadroomLegendPanelKey), findsNothing);
    });

    testWidgets('outside tap dismisses popover', (tester) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Stack(
              children: <Widget>[
                const Positioned.fill(child: SizedBox.expand()),
                Center(
                  child: ImprovementHeadroomLegend(
                    key: anchor,
                    narrow: false,
                    anchorKey: anchor,
                    chromeBottomY: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(kImprovementHeadroomLegendKey));
      await tester.pumpAndSettle();
      expect(find.byKey(kImprovementHeadroomLegendPanelKey), findsOneWidget);

      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(kImprovementHeadroomLegendPanelKey), findsNothing);
    });

    testWidgets('320 dp chip does not overflow', (tester) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: Center(
                child: ImprovementHeadroomLegend(
                  key: anchor,
                  narrow: true,
                  anchorKey: anchor,
                  chromeBottomY: 0,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(kImprovementHeadroomLegendKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
