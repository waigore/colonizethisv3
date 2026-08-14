// Pins MAP10001 extraction-disc legend visibility + popover (Refs #4367).
import 'package:colonizethis_app/features/game/flame/controls/extraction_disc_legend.dart';
import 'package:colonizethis_app/features/game/flame/controls/extraction_disc_legend_support.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map_component_shared_palette.dart'
    show BaseLayerDisplayMode;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  group('shouldShowExtractionDiscLegend', () {
    test('shows in resource-including mode with viewing player', () {
      expect(
        shouldShowExtractionDiscLegend(
          baseLayerDisplayMode:
              BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
          viewingPlayerId: 'gp_player',
        ),
        isTrue,
      );
    });

    test('hides in terrain only even with viewing player', () {
      expect(
        shouldShowExtractionDiscLegend(
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainOnly,
          viewingPlayerId: 'gp_player',
        ),
        isFalse,
      );
    });

    test('hides in global observe even with resource mode', () {
      expect(
        shouldShowExtractionDiscLegend(
          baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
          viewingPlayerId: null,
        ),
        isFalse,
      );
    });
  });

  group('ExtractionDiscLegend chrome', () {
    testWidgets('wide legend shows plain gold/brown labels', (tester) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Center(
              child: ExtractionDiscLegend(
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

      expect(find.byKey(kExtractionDiscLegendKey), findsOneWidget);
      expect(find.text('Reaches capital'), findsOneWidget);
      expect(find.text('Blocked — will not extract'), findsOneWidget);
      expect(find.textContaining('effectiveCapped'), findsNothing);
      expect(find.text('E'), findsNothing);
      expect(find.text('B'), findsNothing);
    });

    testWidgets('narrow legend is chip-only without text labels', (
      tester,
    ) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: SizedBox(
              width: 320,
              child: Center(
                child: ExtractionDiscLegend(
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

      expect(find.byKey(kExtractionDiscLegendKey), findsOneWidget);
      expect(find.text('Reaches capital'), findsNothing);
      expect(find.text('Blocked — will not extract'), findsNothing);
    });

    testWidgets('tap opens popover; close button dismisses', (tester) async {
      final GlobalKey anchor = GlobalKey();
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Center(
              child: ExtractionDiscLegend(
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

      await tester.tap(find.byKey(kExtractionDiscLegendKey));
      await tester.pumpAndSettle();

      expect(find.byKey(kExtractionDiscLegendPanelKey), findsOneWidget);
      expect(
        find.textContaining('Gold: yield that reaches your capital'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Brown: improved yield'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Restore roads, towns, or ports'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(ExtractionDiscLegendPanel.closeButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(kExtractionDiscLegendPanelKey), findsNothing);
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
                  child: ExtractionDiscLegend(
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
      await tester.tap(find.byKey(kExtractionDiscLegendKey));
      await tester.pumpAndSettle();
      expect(find.byKey(kExtractionDiscLegendPanelKey), findsOneWidget);

      // Tap the dimmed scrim (top-left of overlay, away from panel).
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.byKey(kExtractionDiscLegendPanelKey), findsNothing);
    });

    testWidgets('popover close button dismisses', (tester) async {
      await tester.pumpWidget(
        buildAppShell(
          child: Scaffold(
            body: Builder(
              builder: (BuildContext ctx) {
                final AppLocalizations l10n = appL10n(ctx);
                return Center(
                  child: ExtractionDiscLegendPanel(
                    l10n: l10n,
                    onClose: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(kExtractionDiscLegendPanelKey), findsOneWidget);
      expect(
        find.byKey(ExtractionDiscLegendPanel.closeButtonKey),
        findsOneWidget,
      );
    });
  });
}
