// Behavioral AC: Economic row hover invokes onHighlightTile with the row's
// tile key (enter) and null (exit). SPEC/ui/province-sea-zone-detail-overlay.md
// § Acceptance criteria — "Economic row hover sets secondary highlight".

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pEconHover';
const _humanPlayerId = 'gp1';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

RegionMapViewData _regionWithGrainCell() {
  return RegionMapViewData(
    regionId: _regionId,
    width: 1,
    height: 1,
    cellSize: 32,
    cells: const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: _localProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {_humanPlayerId},
    terrainColors: const {},
  );
}

Game _gameWithImprovedGrainTile(String tk) {
  return Game(
    id: 'economic_hover_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullProvinceId,
            regionId: _regionId,
            ownerId: _humanPlayerId,
            displayName: 'EconHover',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        _regionId: {_fullProvinceId: [tk]},
      },
      resourceByTileKey: {tk: 'grain'},
      playerVisibilityByTile: {
        _humanPlayerId: {tk: 'fullyVisible'},
      },
      playerProspectedTiles: {_humanPlayerId: {tk}},
      tileState: TileMapState(improvementByTile: {tk: 2}),
    ),
    players: const [
      Player(
        id: _humanPlayerId,
        displayName: 'Human',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

PlayerView _viewForTile(String tk) {
  return PlayerView(
    playerId: _humanPlayerId,
    player: const Player(
      id: _humanPlayerId,
      displayName: 'Human',
      isHuman: true,
      treasury: 0,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {tk: VisibilityLevel.fullyVisible},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Finder _improvedGrainRowLabelFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains('grain') &&
        (w.data ?? '').contains('with ') &&
        !(w.data ?? '').contains('(improvable)'),
  );
}

Future<TestGesture> _addMousePointer(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: const Offset(-1000, -1000));
  await tester.pump();
  return gesture;
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay Economic row hover (Refs #2865)',
    () {
      testWidgets(
        'AC: hovering an Economic resource row calls onHighlightTile with '
        'that tile key; exit clears to null',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final game = _gameWithImprovedGrainTile(tk);
          final region = _regionWithGrainCell();
          final highlights = <String?>[];

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 800,
                  child: ProvinceSeaZoneDetailOverlay(
                    game: game,
                    region: region,
                    displayId: _fullProvinceId,
                    selectedTileKey: tk,
                    humanPlayerId: _humanPlayerId,
                    playerView: _viewForTile(tk),
                    onHighlightTile: highlights.add,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final rowFinder = _improvedGrainRowLabelFinder();
          expect(
            rowFinder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: improved grain tile must render at least one '
                'Economic resource row.',
          );

          final gesture = await _addMousePointer(tester);
          final center = tester.getCenter(rowFinder.first);
          await gesture.moveTo(center);
          await tester.pump();

          expect(
            highlights,
            contains(tk),
            reason:
                'Economic row hover must invoke onHighlightTile with the '
                'row tile key so panel hosts can set '
                'secondaryHighlightTileKey on the map.',
          );

          await gesture.moveTo(const Offset(-1000, -1000));
          await tester.pump();

          expect(
            highlights.last,
            isNull,
            reason:
                'Exiting the Economic row must invoke onHighlightTile(null) '
                'to clear the secondary map highlight.',
          );
        },
      );
    },
  );
}
