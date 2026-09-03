// Pins MAP10001 owner/sight hover copy and chrome (Refs #4406).
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout_copy.dart';
import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_hover.dart'
    show shouldShowMapTileHoverReadout;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Game _hoverGame() {
  return const Game(
    id: 'hover_readout',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(id: 'gp1', displayName: 'England', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'France', isHuman: false, treasury: 0),
    ],
  );
}

RegionMapViewData _hoverRegion({
  required CellViewData cell,
  List<WarpMarkerView> warpMarkers = const [],
  Map<String, String> seaNames = const {},
}) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: 1,
    height: 1,
    cellSize: 16,
    cells: [cell],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1', 'gp2'},
    terrainColors: const {},
    warpMarkers: warpMarkers,
    seaZoneDisplayNameByPrefixedId: seaNames,
  );
}

void main() {
  suppressLogsForTests();
  final l10n = lookupAppLocalizations(const Locale('en'));
  final game = _hoverGame();

  group('tryMapTileHoverReadoutCopy', () {
    test('owned visible land uses Place, Owner, Fully visible', () {
      final copy = tryMapTileHoverReadoutCopy(
        l10n: l10n,
        game: game,
        region: _hoverRegion(
          cell: const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            ownerFactionId: 'gp1',
            provinceDisplayName: 'Wessex',
            terrainTypeId: 'plains',
            resourceId: 'grain',
            visibility: TileVisibility.visible,
          ),
        ),
        tileKey: 'oldWorld|p1|0|0',
      );
      expect(copy, isNotNull);
      expect(copy!.placeLine, 'Place: Wessex');
      expect(copy.identityLine, 'Owner: England');
      expect(copy.sightLine, 'Sight: Fully visible');
      expect(copy.warpLine, isNull);
      expect(copy.placeLine, isNot(contains('plains')));
      expect(copy.identityLine, isNot(contains('grain')));
    });

    test('fogged rival land keeps authoritative owner', () {
      final copy = tryMapTileHoverReadoutCopy(
        l10n: l10n,
        game: game,
        region: _hoverRegion(
          cell: const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p2',
            isSea: false,
            ownerFactionId: 'gp2',
            provinceDisplayName: 'Normandy',
            visibility: TileVisibility.fogged,
          ),
        ),
        tileKey: 'oldWorld|p2|0|0',
      );
      expect(copy!.identityLine, 'Owner: France');
      expect(copy.sightLine, 'Sight: Fogged — terrain only');
    });

    test('unrevealed land shows owner without terrain or resource', () {
      final copy = tryMapTileHoverReadoutCopy(
        l10n: l10n,
        game: game,
        region: _hoverRegion(
          cell: const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p3',
            isSea: false,
            ownerFactionId: 'gp2',
            provinceDisplayName: 'Virginia',
            terrainTypeId: 'hills',
            resourceId: 'iron',
            improvementLevel: 2,
            visibility: TileVisibility.unrevealed,
          ),
        ),
        tileKey: 'oldWorld|p3|0|0',
      );
      expect(copy!.identityLine, 'Owner: France');
      expect(copy.sightLine, 'Sight: Unknown — no intel yet');
      expect(copy.placeLine, isNot(contains('hills')));
      expect(copy.identityLine, isNot(contains('iron')));
      expect(copy.sightLine, isNot(contains('improvement')));
    });

    test('unclaimed land uses Unclaimed owner', () {
      final copy = tryMapTileHoverReadoutCopy(
        l10n: l10n,
        game: game,
        region: _hoverRegion(
          cell: const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p4',
            isSea: false,
            provinceDisplayName: 'Wilderness',
            visibility: TileVisibility.visible,
          ),
        ),
        tileKey: 'oldWorld|p4|0|0',
      );
      expect(copy!.identityLine, 'Owner: Unclaimed');
    });

    test('sea cell uses sea-zone identity not owner', () {
      final copy = tryMapTileHoverReadoutCopy(
        l10n: l10n,
        game: game,
        region: _hoverRegion(
          cell: const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 's1',
            isSea: true,
            visibility: TileVisibility.visible,
          ),
          seaNames: const {'oldWorld|s1': 'Mid-Atlantic'},
        ),
        tileKey: 'oldWorld|s1|0|0',
      );
      expect(copy!.placeLine, 'Place: Mid-Atlantic');
      expect(copy.identityLine, 'Sea zone');
      expect(copy.identityLine, isNot(contains('Owner:')));
      expect(copy.warpLine, isNull);
    });

    test('warp sea adds passage line', () {
      final copy = tryMapTileHoverReadoutCopy(
        l10n: l10n,
        game: game,
        region: _hoverRegion(
          cell: const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'sWarp',
            isSea: true,
            visibility: TileVisibility.fogged,
          ),
          warpMarkers: const [
            WarpMarkerView(
              x: 0,
              y: 0,
              seaZoneId: 'sWarp',
              otherRegionId: 'newWorld',
              otherSeaZoneId: 'sOther',
            ),
          ],
          seaNames: const {'oldWorld|sWarp': 'Azores Passage'},
        ),
        tileKey: 'oldWorld|sWarp|0|0',
      );
      expect(copy!.warpLine, 'This water is the passage to the other world');
      expect(copy.sightLine, 'Sight: Fogged — terrain only');
    });
  });

  group('shouldShowMapTileHoverReadout', () {
    test('hides during work-target selection', () {
      expect(
        shouldShowMapTileHoverReadout(
          inWorkTargetSelectionMode: true,
          hoveredTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });

    test('hides when pointer leaves', () {
      expect(
        shouldShowMapTileHoverReadout(
          inWorkTargetSelectionMode: false,
          hoveredTileKey: null,
        ),
        isFalse,
      );
    });
  });
}
