// Issue #1537 — Tile section shows numeric road/rail transport level + supplementary GDD labels.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart';
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/l10n/app_localizations_en.dart';

void main() {
  suppressLogsForTests();

  // Road / railroad Tile lines resolve through AppLocalizations (Refs #2865);
  // the English implementation pins the canonical copy these ACs assert.
  final l10n = AppLocalizationsEn();

  group('road/rail transport Tile copy (issue #1537)', () {
    test('AC: sea / no land transport — single road/rail none line', () {
      expect(roadRailTileDetailLinesForTests(l10n: l10n, transportLevel: null), [
        l10n.provinceOverlay_tileRoadNone,
      ]);
    });

    test('AC: land level 0 — numeric 0 and supplementary none', () {
      expect(roadRailTileDetailLinesForTests(l10n: l10n, transportLevel: 0), [
        'Road / railroad: transport level 0',
        'none',
      ]);
    });

    test('AC: land level 1 — numeric 1, primitive road, rail gloss', () {
      expect(roadRailTileDetailLinesForTests(l10n: l10n, transportLevel: 1), [
        'Road / railroad: transport level 1',
        'primitive road',
        l10n.provinceOverlay_tileRoadRailGloss,
      ]);
    });

    test('AC: land level 2 — numeric 2 and improved road', () {
      expect(roadRailTileDetailLinesForTests(l10n: l10n, transportLevel: 2), [
        'Road / railroad: transport level 2',
        'improved road',
      ]);
    });

    test('AC: land level 4 — numeric 4 and port or railroad', () {
      expect(roadRailTileDetailLinesForTests(l10n: l10n, transportLevel: 4), [
        'Road / railroad: transport level 4',
        'port or railroad',
      ]);
    });

    test(
      'AC: unexpected positive level — numeric shown and non-standard label',
      () {
        expect(roadRailTileDetailLinesForTests(l10n: l10n, transportLevel: 3), [
          'Road / railroad: transport level 3',
          'non-standard transport level',
        ]);
      },
    );

    test('AC: road/rail Tile lines resolve from AppLocalizations keys', () {
      expect(
        roadRailTransportLevelPrimaryLine(l10n, 2),
        l10n.provinceOverlay_tileRoadTransportLevel(2),
      );
      expect(roadRailSupplementaryLabel(l10n, 0), l10n.provinceOverlay_tileRoadLabelNone);
      expect(
        roadRailSupplementaryLabel(l10n, 1),
        l10n.provinceOverlay_tileRoadLabelPrimitiveRoad,
      );
      expect(
        roadRailSupplementaryLabel(l10n, 2),
        l10n.provinceOverlay_tileRoadLabelImprovedRoad,
      );
      expect(
        roadRailSupplementaryLabel(l10n, 4),
        l10n.provinceOverlay_tileRoadLabelPortOrRailroad,
      );
      expect(
        roadRailSupplementaryLabel(l10n, 7),
        l10n.provinceOverlay_tileRoadLabelNonStandard,
      );
    });
  });

  group('ProvinceSeaZoneDetailOverlay Tile road/rail wiring', () {
    testWidgets(
      'AC: overlay shows transport level and supplementary label from game state',
      (WidgetTester tester) async {
        final base = demoGameForOverlay;
        final region = demoRegionForOverlay;
        final tileKey = sampleTileKeyForProvinceOverlay;
        final humanPlayerId = base.players.first.id;
        // Refs #3656: buildPlayerView ignores its topology argument, so an
        // empty const MapTopology() replaces the ~11s getDebugInitGameResult()
        // map generation with identical PlayerView output for this demo game.
        final playerView = buildPlayerView(
          base,
          const MapTopology(),
          humanPlayerId,
        );

        final ws = base.worldState;
        final tileState = ws.tileState.setRoadLevel(tileKey, 2);
        final game = base.copyWith(
          worldState: ws.copyWith(tileState: tileState),
        );

        final parts = tileKey.split('|');
        expect(parts.length, greaterThanOrEqualTo(4));
        final provinceId = '${parts[0]}|${parts[1]}';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProvinceSeaZoneDetailOverlay(
                game: game,
                region: region,
                displayId: provinceId,
                selectedTileKey: tileKey,
                humanPlayerId: humanPlayerId,
                playerView: playerView,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Road / railroad: transport level 2'), findsOneWidget);
        expect(find.text('improved road'), findsOneWidget);
      },
    );
  });
}
