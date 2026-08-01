// Tile capital-link and per-tile extraction rows on MAP20001 (Refs #4149, #4224).

import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_labels.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'province_overlay_tile_capital_link_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('provinceTileConnectivityDisplayPreview (Refs #4149)', () {
    for (final case_ in tileCapitalLinkPreviewCases()) {
      test(case_.name, () {
        final game = case_.buildGame();
        final preview = tileCapitalLinkPreview(
          game: game,
          provinceId: case_.provinceId,
          selectedTileKey: case_.selectedTileKey,
          isSeaZoneContext: case_.isSeaZoneContext,
          tileIsSea: case_.tileIsSea,
          tileRevealed: case_.tileRevealed,
          connectivityForHuman: case_.connectivityForHuman,
        );
        if (case_.expectNull) {
          expect(preview, isNull);
          return;
        }
        expect(preview, isNotNull);
        expect(preview!.capitalConnected, case_.capitalConnected);
        expect(preview.showExtractionRow, case_.showExtractionRow);
        if (case_.extractionEffective != null) {
          expect(preview.extractionEffective, case_.extractionEffective);
        } else if (case_.effectiveLessThanFull == false) {
          expect(preview.extractionEffective, preview.extractionFull);
        }
        if (case_.extractionFull != null) {
          expect(preview.extractionFull, case_.extractionFull);
        } else {
          expect(preview.extractionEffective, isNull);
          expect(preview.extractionFull, isNull);
        }
        if (case_.effectiveLessThanFull == true) {
          expect(preview.extractionEffective! < preview.extractionFull!, isTrue);
        }
      });
    }
  });

  group('ProvinceSeaZoneDetailOverlay tile capital-link UI (Refs #4149)', () {
    for (final case_ in tileCapitalLinkOverlayCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpTileCapitalLinkOverlayCase(tester, case_);
        if (case_.expectNoCapitalLink) {
          expect(find.textContaining('Capital link:'), findsNothing);
        } else {
          expect(
            find.textContaining(case_.capitalLinkSnippet!),
            findsOneWidget,
          );
        }
        if (case_.expectNoExtraction) {
          expect(find.textContaining('Extraction from this tile:'), findsNothing);
        } else {
          expect(
            find.textContaining(case_.extractionSnippet!),
            findsOneWidget,
          );
        }
      });
    }
  });

  group('ProvinceSeaZoneDetailOverlay tile capital-link goldens (Refs #4149)', () {
    testWidgets('golden: disconnected tile shows capital link and 0 of F', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'province_overlay_tile_capital_link_disconnected_golden',
      );
      final game = tileCapitalLinkGame(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 0,
      );
      await pumpTileCapitalLinkGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        displayId: kTileCapitalLinkRemoteProvinceId,
        selectedTileKey: kTileCapitalLinkRemoteTile,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: false,
          extractionEffective: 0,
          extractionFull: 3,
        ),
      );
      expect(
        find.textContaining('Capital link: Not connected'),
        findsOneWidget,
      );
      expect(find.textContaining('Extraction from this tile: 0 of 3'),
          findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_tile_capital_link_disconnected.png',
        ),
      );
    });

    testWidgets('golden: connected tile shows capital link and E of F', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>(
        'province_overlay_tile_capital_link_connected_golden',
      );
      final game = tileCapitalLinkGame(
        remoteImprovementLevel: 3,
        remoteRoadLevel: 4,
      );
      await pumpTileCapitalLinkGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        displayId: kTileCapitalLinkProvinceId,
        selectedTileKey: kTileCapitalLinkCapitalTile,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: true,
          pathTransportLevel: 2,
          extractionEffective: 2,
          extractionFull: 3,
        ),
      );
      expect(find.textContaining('Capital link: Connected'), findsOneWidget);
      expect(find.textContaining('Extraction from this tile: 2 of 3'),
          findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_tile_capital_link_connected.png',
        ),
      );
    });
  });

  group('tileConnectivityDetailLinesForTests', () {
    test('formats connected and extraction lines', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final lines = tileConnectivityDetailLinesForTests(
        l10n: l10n,
        tileConnectivity: const ProvinceTileConnectivityDisplay(
          capitalConnected: true,
          pathTransportLevel: 2,
          extractionEffective: 1,
          extractionFull: 4,
        ),
      );
      expect(lines, [
        'Capital link: Connected (path transport level 2)',
        'Extraction from this tile: 1 of 4',
      ]);
    });
  });
}
