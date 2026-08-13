/// Tile details disclosure tests for MAP20001 (Refs #4369).
library;

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_details.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_tile_capital_link_test_fixtures.dart';
import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  group('MAP20001 Tile details disclosure (Refs #4369)', () {
    test('detail lines suppress E of F when E is zero', () {
      final game = tileCapitalLinkGame(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      final lines = provinceTileDetailsLines(
        l10n: l10n,
        game: game,
        humanPlayerId: kTileCapitalLinkHumanId,
        provinceId: kTileCapitalLinkRemoteProvinceId,
        roadLevel: 0,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: false,
          extractionEffective: 0,
          extractionFull: 3,
        ),
      );
      expect(lines, contains(l10n.provinceOverlay_tileRoadLabelNone));
      expect(lines, contains(l10n.provinceOverlay_tilePortStatusNone));
      expect(lines, contains(l10n.provinceOverlay_tileCapitalLinkNotConnected));
      expect(
        lines.any((l) => l.contains('Extraction from this tile:')),
        isFalse,
      );
    });

    test('detail lines include E of F when E > 0 and F > 0', () {
      final game = tileCapitalLinkGame(
        remoteImprovementLevel: 2,
        remoteRoadLevel: 4,
      );
      final lines = provinceTileDetailsLines(
        l10n: l10n,
        game: game,
        humanPlayerId: kTileCapitalLinkHumanId,
        provinceId: kTileCapitalLinkProvinceId,
        roadLevel: 4,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: true,
          pathTransportLevel: 4,
          extractionEffective: 1,
          extractionFull: 1,
        ),
      );
      expect(lines, contains(l10n.provinceOverlay_tileRoadLabelPortOrRailroad));
      expect(
        lines,
        contains(l10n.provinceOverlay_tileExtractionFromTile(1, 1)),
      );
    });

    testWidgets(
      'default surface hides teaching; Tile details reveals it',
      (WidgetTester tester) async {
        final game = tileCapitalLinkGame(
          remoteImprovementLevel: 0,
          remoteRoadLevel: 0,
        );
        await tester.pumpWidget(
          buildProvinceOverlayDarkThemeShell(
            game: game,
            region: tileCapitalLinkRegionForGame(game),
            displayId: kTileCapitalLinkProvinceId,
            selectedTileKey: kTileCapitalLinkCapitalTile,
            humanPlayerId: kTileCapitalLinkHumanId,
            playerView: demoOverlayPlayerView(game),
            tileConnectivity: const ProvinceTileConnectivityDisplay(
              capitalConnected: true,
              pathTransportLevel: 4,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Road / railroad: transport level 4'), findsOneWidget);
        expect(find.text('port or railroad'), findsNothing);
        expect(find.textContaining('Port:'), findsNothing);
        expect(find.textContaining('Capital link:'), findsNothing);
        expect(find.textContaining('Extraction from this tile:'), findsNothing);
        expect(find.byKey(kProvinceTileDetailsActionKey), findsOneWidget);

        await tester.tap(find.byKey(kProvinceTileDetailsActionKey));
        await tester.pumpAndSettle();

        expect(find.byKey(kProvinceTileDetailsPanelKey), findsOneWidget);
        expect(find.text('port or railroad'), findsOneWidget);
        expect(find.textContaining('Port:'), findsOneWidget);
        expect(find.textContaining('Capital link: Connected'), findsOneWidget);
      },
    );

    testWidgets(
      'stranded exception stays on default; details omit 0 of F',
      (WidgetTester tester) async {
        final game = tileCapitalLinkGame(
          remoteImprovementLevel: 3,
          remoteRoadLevel: 0,
        );
        await tester.pumpWidget(
          buildProvinceOverlayDarkThemeShell(
            game: game,
            region: tileCapitalLinkRegionForGame(game),
            displayId: kTileCapitalLinkRemoteProvinceId,
            selectedTileKey: kTileCapitalLinkRemoteTile,
            humanPlayerId: kTileCapitalLinkHumanId,
            playerView: demoOverlayPlayerView(game),
            tileConnectivity: const ProvinceTileConnectivityDisplay(
              capitalConnected: false,
              extractionEffective: 0,
              extractionFull: 3,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Capital link: Not connected'),
          findsOneWidget,
        );
        expect(find.textContaining('Extraction from this tile:'), findsNothing);

        await tester.tap(find.byKey(kProvinceTileDetailsClusterKey));
        await tester.pumpAndSettle();

        expect(find.byKey(kProvinceTileDetailsPanelKey), findsOneWidget);
        expect(
          find.textContaining('Capital link: Not connected'),
          findsWidgets,
        );
        expect(
          find.textContaining('Extraction from this tile: 0 of 3'),
          findsNothing,
        );
      },
    );

    testWidgets('Tile details dismisses via Close', (WidgetTester tester) async {
      final game = tileCapitalLinkGame(
        remoteImprovementLevel: 0,
        remoteRoadLevel: 0,
      );
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          region: tileCapitalLinkRegionForGame(game),
          displayId: kTileCapitalLinkProvinceId,
          selectedTileKey: kTileCapitalLinkCapitalTile,
          humanPlayerId: kTileCapitalLinkHumanId,
          playerView: demoOverlayPlayerView(game),
          tileConnectivity: const ProvinceTileConnectivityDisplay(
            capitalConnected: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(kProvinceTileDetailsActionKey));
      await tester.pumpAndSettle();
      expect(find.byKey(kProvinceTileDetailsPanelKey), findsOneWidget);
      await tester.tap(find.byKey(ProvinceTileDetailsDialog.closeButtonKey));
      await tester.pumpAndSettle();
      expect(find.byKey(kProvinceTileDetailsPanelKey), findsNothing);
    });
  });
}
