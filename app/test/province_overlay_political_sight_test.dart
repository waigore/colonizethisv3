// Pins MAP20001 Political Sight row (Refs #4406).
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';

const String _kHumanId = 'gp_human';
const String _kProvinceId = 'oldWorld|p1';
const String _kTileKey = 'oldWorld|p1|0|0';

Game _sightGame() {
  return Game(
    id: 'political_sight',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: _kProvinceId,
            regionId: 'oldWorld',
            displayName: 'Wessex',
            ownerId: _kHumanId,
            townTileKey: _kTileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: _kHumanId, displayName: 'England', isHuman: true, treasury: 0),
    ],
  );
}

RegionMapViewData _sightRegion(TileVisibility visibility) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: 'p1',
        isSea: false,
        ownerFactionId: _kHumanId,
        provinceDisplayName: 'Wessex',
        visibility: visibility,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {_kHumanId},
    terrainColors: const {},
    provincePoliticalOwnerByPrefixedProvinceId: const {_kProvinceId: _kHumanId},
  );
}

Finder _findTextStartingWith(String prefix) => find.byWidgetPredicate(
  (Widget w) => w is Text && (w.data ?? '').startsWith(prefix),
);

void main() {
  suppressLogsForTests();

  testWidgets('Political Sight row uses Fully visible phrase', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: _sightGame(),
        displayId: _kProvinceId,
        region: _sightRegion(TileVisibility.visible),
        selectedTileKey: _kTileKey,
        omniscientDetail: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sight: Fully visible'), findsOneWidget);
    expect(find.textContaining('TileVisibility'), findsNothing);
    expect(find.text('visible'), findsNothing);
    final Text row = tester.widget<Text>(_findTextStartingWith('Sight:').first);
    expect(row.style?.color, EditorialMonoclePalette.fg);
  });

  testWidgets('Political Sight row uses Fogged phrase', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: _sightGame(),
        displayId: _kProvinceId,
        region: _sightRegion(TileVisibility.fogged),
        selectedTileKey: _kTileKey,
        omniscientDetail: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sight: Fogged — terrain only'), findsOneWidget);
  });

  testWidgets('Political Sight row uses Unknown phrase', (tester) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: _sightGame(),
        displayId: _kProvinceId,
        region: _sightRegion(TileVisibility.unrevealed),
        selectedTileKey: _kTileKey,
        omniscientDetail: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sight: Unknown — no intel yet'), findsOneWidget);
  });

  testWidgets('Political Sight row does not overflow at 320 dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: _sightGame(),
        displayId: _kProvinceId,
        region: _sightRegion(TileVisibility.visible),
        selectedTileKey: _kTileKey,
        omniscientDetail: true,
        viewport: const Size(320, 640),
        shellWidth: 320,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sight: Fully visible'), findsOneWidget);
  });

  testWidgets('Political omits Sight when no selected tile cell', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: _sightGame(),
        displayId: _kProvinceId,
        region: _sightRegion(TileVisibility.visible),
        selectedTileKey: null,
        omniscientDetail: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Sight:'), findsNothing);
  });

  testWidgets('sea-zone Political includes Sight row', (tester) async {
    const seaId = 'oldWorld|s1';
    const seaTile = 'oldWorld|s1|0|0';
    final region = RegionMapViewData(
      regionId: 'oldWorld',
      width: 1,
      height: 1,
      cellSize: 16,
      cells: const [
        CellViewData(
          x: 0,
          y: 0,
          regionCellId: 's1',
          isSea: true,
          visibility: TileVisibility.fogged,
        ),
      ],
      capitalMarkers: const [],
      portMarkers: const [],
      factionColors: const {},
      greatPowerFactionIds: const {},
      terrainColors: const {},
      seaZoneDisplayNameByPrefixedId: const {seaId: 'Mid-Atlantic'},
    );
    await tester.pumpWidget(
      buildProvinceOverlayDarkThemeShell(
        game: _sightGame(),
        displayId: seaId,
        region: region,
        selectedTileKey: seaTile,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sight: Fogged — terrain only'), findsOneWidget);
  });
}
