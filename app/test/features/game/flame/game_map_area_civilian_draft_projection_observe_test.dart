import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/flame/game_map_area_civilian_draft_projection.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_models/colonizethis_models.dart'
    show kUnitTypeBuilder, kUnitTypeExplorer;

// Coverage for SPEC/ui/observe-mode.md § Map civilian markers — projection
// layer (Refs #2685). The projection must accept an explicit owner set so
// observe handoff (Player.isHuman = false on every player) does not empty
// the unit lookup, and so non-pending civilians from multiple owners still
// survive the round-trip.
void main() {
  suppressLogsForTests();

  group(
    'GameMapAreaCivilianDraftProjection.project civilianMarkerOwnerIds',
    () {
      test(
        'projection enumerates multi-owner civilians when an explicit owner '
        'set is provided and pending orders are empty (Refs #2685 AC global)',
        () {
          final region = _regionWithBaseCivilianMarkers(
            regionId: 'oldWorld',
            ownerIdByTile: {
              'oldWorld|p1|0|0': 'gp1',
              'oldWorld|p2|1|0': 'gp2',
            },
          );
          final game = _twoGpCivilianGame();
          const orders = ct_models.Orders();

          final projected = GameMapAreaCivilianDraftProjection.project(
            region: region,
            game: game,
            orders: orders,
            humanPlayerId: 'gp1',
            civilianMarkerOwnerIds: {'gp1', 'gp2'},
          );

          final tileKeys = projected.civilianTileMarkers
              .map((m) => m.tileKey)
              .toList()
            ..sort();
          expect(tileKeys, equals(['oldWorld|p1|0|0', 'oldWorld|p2|1|0']));
        },
      );

      test(
        'projection drops markers whose owner is not in the supplied owner '
        'set (Refs #2685 AC player observe)',
        () {
          final region = _regionWithBaseCivilianMarkers(
            regionId: 'oldWorld',
            ownerIdByTile: {
              'oldWorld|p1|0|0': 'gp1',
              'oldWorld|p2|1|0': 'gp2',
            },
          );
          final game = _twoGpCivilianGame();
          const orders = ct_models.Orders();

          final projected = GameMapAreaCivilianDraftProjection.project(
            region: region,
            game: game,
            orders: orders,
            humanPlayerId: 'gp2',
            civilianMarkerOwnerIds: {'gp2'},
          );

          expect(projected.civilianTileMarkers, hasLength(1));
          expect(
            projected.civilianTileMarkers.single.tileKey,
            'oldWorld|p2|1|0',
          );
        },
      );

      test(
        'null civilianMarkerOwnerIds preserves legacy single-player projection '
        'behavior (Refs #2685 AC off)',
        () {
          final region = _regionWithBaseCivilianMarkers(
            regionId: 'oldWorld',
            ownerIdByTile: {'oldWorld|p1|0|0': 'gp1'},
          );
          final game = _twoGpCivilianGame();
          const orders = ct_models.Orders();

          final projected = GameMapAreaCivilianDraftProjection.project(
            region: region,
            game: game,
            orders: orders,
            humanPlayerId: 'gp1',
            civilianMarkerOwnerIds: null,
          );

          expect(projected.civilianTileMarkers, hasLength(1));
          expect(
            projected.civilianTileMarkers.single.tileKey,
            'oldWorld|p1|0|0',
          );
        },
      );

      test(
        'state-logic forwarder threads civilianMarkerOwnerIds through to the '
        'projection module (Refs #2685 wiring)',
        () {
          final region = _regionWithBaseCivilianMarkers(
            regionId: 'oldWorld',
            ownerIdByTile: {
              'oldWorld|p1|0|0': 'gp1',
              'oldWorld|p2|1|0': 'gp2',
            },
          );
          final game = _twoGpCivilianGame();
          const orders = ct_models.Orders();

          final viaForwarder =
              GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
                region: region,
                game: game,
                orders: orders,
                humanPlayerId: 'gp1',
                civilianMarkerOwnerIds: {'gp1', 'gp2'},
              );
          final viaDirect = GameMapAreaCivilianDraftProjection.project(
            region: region,
            game: game,
            orders: orders,
            humanPlayerId: 'gp1',
            civilianMarkerOwnerIds: {'gp1', 'gp2'},
          );

          final forwarderTileKeys = viaForwarder.civilianTileMarkers
              .map((m) => m.tileKey)
              .toList()
            ..sort();
          final directTileKeys = viaDirect.civilianTileMarkers
              .map((m) => m.tileKey)
              .toList()
            ..sort();
          expect(forwarderTileKeys, equals(directTileKeys));
        },
      );
    },
  );
}

ct_models.Game _twoGpCivilianGame() {
  return ct_models.Game(
    id: 'observe_two_gp',
    worldState: ct_models.WorldState(
      turnState: const ct_models.TurnState(
        phase: ct_models.TurnPhase.orders,
        turnNumber: 1,
      ),
      oldWorld: ct_models.RegionData(
        provinces: const [
          ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
          ct_models.Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
        ],
        units: [
          ct_models.Unit(
            id: 'gp1_builder',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
            tileKey: 'oldWorld|p1|0|0',
            status: ct_models.UnitStatus.idle,
          ),
          ct_models.Unit(
            id: 'gp2_explorer',
            type: kUnitTypeExplorer,
            ownerId: 'gp2',
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|1|0',
            status: ct_models.UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const ct_models.RegionData(provinces: [], units: []),
    ),
    players: const [
      // Observe handoff sets every player isHuman=false; verify projection
      // works without relying on the flag.
      ct_models.Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      ct_models.Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

RegionMapViewData _regionWithBaseCivilianMarkers({
  required String regionId,
  required Map<String, String> ownerIdByTile,
}) {
  final markers = <CivilianTileMarkerView>[];
  ownerIdByTile.forEach((tileKey, ownerId) {
    final parts = tileKey.split('|');
    final x = int.parse(parts[2]);
    final y = int.parse(parts[3]);
    final unitId = ownerId == 'gp1' ? 'gp1_builder' : 'gp2_explorer';
    final unitType = ownerId == 'gp1' ? kUnitTypeBuilder : kUnitTypeExplorer;
    markers.add(
      CivilianTileMarkerView(
        tileKey: tileKey,
        x: x,
        y: y,
        localProvinceId: parts[1],
        unitIds: [unitId],
        unitTypes: {unitId: unitType},
        representativeUnitType: unitType,
        stackCount: 1,
        representativeIsAssigned: false,
      ),
    );
  });
  return RegionMapViewData(
    regionId: regionId,
    width: 2,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
      CellViewData(x: 1, y: 0, regionCellId: 'p2', isSea: false),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
    unitMarkers: const [],
    civilianTileMarkers: markers,
  );
}
