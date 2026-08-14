// Visual goldens for MAP20001 Tile details helper (Refs #4369).
// SPEC/ui/province-sea-zone-detail-overlay.md § Tile details disclosure.
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_details.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_tile_capital_link_test_fixtures.dart';
import 'widget_test_assets.dart';

const ProvinceTileConnectivityDisplay _connectedExtraction =
    ProvinceTileConnectivityDisplay(
      capitalConnected: true,
      pathTransportLevel: 2,
      extractionEffective: 2,
      extractionFull: 3,
    );

List<String> _connectedDetailsLines(AppLocalizationsEn l10n) {
  final Game game = tileCapitalLinkGame(
    remoteImprovementLevel: 3,
    remoteRoadLevel: 4,
  );
  return provinceTileDetailsLines(
    l10n: l10n,
    game: game,
    humanPlayerId: kTileCapitalLinkHumanId,
    provinceId: kTileCapitalLinkProvinceId,
    roadLevel: 4,
    tileConnectivity: _connectedExtraction,
  );
}

void main() {
  suppressLogsForTests();
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: Tile details helper lists caption, port, capital-link, E of F '
    '(Refs #4369)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'province_overlay_tile_details_dialog_golden',
      );
      final List<String> lines = _connectedDetailsLines(l10n);
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 480),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: ProvinceTileDetailsDialog(l10n: l10n, lines: lines),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
      expect(find.byKey(kProvinceTileDetailsPanelKey), findsOneWidget);
      expect(find.text('port or railroad'), findsOneWidget);
      expect(find.textContaining('Port:'), findsOneWidget);
      expect(find.textContaining('Capital link: Connected'), findsOneWidget);
      expect(
        find.textContaining('Extraction from this tile: 2 of 3'),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/province_overlay_tile_details_dialog.png'),
      );
    },
  );

  testWidgets(
    'golden: Tile details helper open @ 320dp from overlay (Refs #4369)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'province_overlay_tile_details_dialog_320dp_golden',
      );
      final Game game = tileCapitalLinkGame(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 4,
      );
      await configureGoldenSurface(
        tester,
        size: const Size(kMinViewportWidth, 640),
      );
      configureGoldenView(
        tester,
        physicalSize: const Size(kMinViewportWidth, 640),
      );
      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          center: false,
          child: SizedBox(
            width: kMinViewportWidth,
            height: 640,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: tileCapitalLinkRegionForGame(game),
              displayId: kTileCapitalLinkProvinceId,
              selectedTileKey: kTileCapitalLinkCapitalTile,
              humanPlayerId: kTileCapitalLinkHumanId,
              playerView: buildPlayerView(
                game,
                const MapTopology(),
                kTileCapitalLinkHumanId,
              ),
              draftOrders: const Orders(),
              tileConnectivity: _connectedExtraction,
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      await tester.tap(find.text(l10n.provinceOverlay_sectionTile));
      await tester.pump();
      await tester.tap(find.byKey(kProvinceTileDetailsActionKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
      expect(find.byKey(kProvinceTileDetailsPanelKey), findsOneWidget);
      expect(
        find.textContaining('Extraction from this tile: 0 of'),
        findsNothing,
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/province_overlay_tile_details_dialog_320dp.png',
        ),
      );
    },
  );
}
