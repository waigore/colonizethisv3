import 'package:colonizethis_app/features/game/flame/game_map_area_civilian_draft_projection.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area_fleet_draft_projection.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area_province_action_states.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter_test/flutter_test.dart';

/// #2575 work item 11 — module split sanity checks.
///
/// Confirms the new dedicated modules expose the same projection / action
/// state behavior as the legacy `GameMapAreaStateLogic` static entry points
/// (forwarders). Heavier scenario coverage lives in the existing
/// `game_map_area_state_logic_test_part1/2/3_test.dart` suites, which still
/// drive the public `GameMapAreaStateLogic.*` API and exercise the
/// forwarder path end-to-end.
void main() {
  group('GameMapAreaCivilianDraftProjection (Refs #2575)', () {
    test('project on empty draft returns the input region unchanged', () {
      final region = _emptyRegion('oldWorld');
      final game = _gameWithNoUnits();
      const orders = ct_models.Orders();
      final result = GameMapAreaCivilianDraftProjection.project(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: 'gp1',
      );
      expect(identical(result, region), isTrue);
    });

    test('legacy forwarder returns same result as direct module call', () {
      final region = _emptyRegion('oldWorld');
      final game = _gameWithNoUnits();
      const orders = ct_models.Orders();
      final viaForwarder =
          GameMapAreaStateLogic.projectCivilianMarkersForHumanDraft(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: 'gp1',
      );
      final viaDirect = GameMapAreaCivilianDraftProjection.project(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: 'gp1',
      );
      expect(viaForwarder.civilianTileMarkers, viaDirect.civilianTileMarkers);
      expect(viaForwarder.regionId, viaDirect.regionId);
    });
  });

  group('GameMapAreaFleetDraftProjection (Refs #2575)', () {
    test('project with no fleet markers returns input region unchanged', () {
      final region = _emptyRegion('oldWorld');
      final game = _gameWithNoUnits();
      const orders = ct_models.Orders();
      final result = GameMapAreaFleetDraftProjection.project(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: 'gp1',
        tileMapByRegion: const {},
        topologyByRegion: const {},
        combinedTopology: const MapTopology(),
      );
      expect(identical(result, region), isTrue);
    });

    test('legacy forwarder returns same result as direct module call', () {
      final region = _emptyRegion('oldWorld');
      final game = _gameWithNoUnits();
      const orders = ct_models.Orders();
      const topology = MapTopology();
      final viaForwarder =
          GameMapAreaStateLogic.projectFleetMarkersForHumanDraft(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: 'gp1',
        tileMapByRegion: const {},
        topologyByRegion: const {},
        combinedTopology: topology,
      );
      final viaDirect = GameMapAreaFleetDraftProjection.project(
        region: region,
        game: game,
        orders: orders,
        humanPlayerId: 'gp1',
        tileMapByRegion: const {},
        topologyByRegion: const {},
        combinedTopology: topology,
      );
      expect(viaForwarder.fleetTileMarkers, viaDirect.fleetTileMarkers);
      expect(viaForwarder.regionId, viaDirect.regionId);
    });
  });

  group('GameMapAreaProvinceActionStates (Refs #2575)', () {
    test(
      'explore returns hidden state for malformed tile key (negative)',
      () {
        final region = _emptyRegion('oldWorld');
        final state = GameMapAreaProvinceActionStates.explore(
          game: _gameWithNoUnits(),
          humanPlayerId: 'gp1',
          selectedTileKey: 'bad',
          selectedRegion: region,
        );
        expect(
          state,
          GameMapAreaProvinceActionStates.kHiddenExplorerInlineActionState,
        );
      },
    );

    test('buildImprovement returns hidden state for malformed tile key', () {
      final state = GameMapAreaProvinceActionStates.buildImprovement(
        game: _gameWithNoUnits(),
        humanPlayerId: 'gp1',
        selectedTileKey: 'bad',
        playerView: _emptyPlayerView('gp1'),
      );
      expect(
        state,
        GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState,
      );
    });

    test('prospect returns hidden state for malformed tile key', () {
      final state = GameMapAreaProvinceActionStates.prospect(
        game: _gameWithNoUnits(),
        humanPlayerId: 'gp1',
        selectedTileKey: 'bad',
        playerView: _emptyPlayerView('gp1'),
        topology: null,
        currentOrders: const ct_models.Orders(),
        tileMapByRegion: null,
      );
      expect(state.showIcon, isFalse);
      expect(state.enabled, isFalse);
    });

    test(
      'legacy state-logic constants forward to province-actions module',
      () {
        expect(
          GameMapAreaStateLogic.kHiddenExplorerInlineActionState,
          GameMapAreaProvinceActionStates.kHiddenExplorerInlineActionState,
        );
        expect(
          GameMapAreaStateLogic.kHiddenBuilderInlineActionState,
          GameMapAreaProvinceActionStates.kHiddenBuilderInlineActionState,
        );
      },
    );

    test('forwarder buildImprovement parity with direct module call', () {
      final game = _gameWithNoUnits();
      final view = _emptyPlayerView('gp1');
      final viaForwarder =
          GameMapAreaStateLogic.provinceBuildImprovementActionState(
        game: game,
        humanPlayerId: 'gp1',
        selectedTileKey: 'bad',
        playerView: view,
      );
      final viaDirect = GameMapAreaProvinceActionStates.buildImprovement(
        game: game,
        humanPlayerId: 'gp1',
        selectedTileKey: 'bad',
        playerView: view,
      );
      expect(viaForwarder, viaDirect);
    });
  });
}

RegionMapViewData _emptyRegion(String regionId) {
  return RegionMapViewData(
    regionId: regionId,
    width: 1,
    height: 1,
    cellSize: 16,
    cells: const [
      CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
    ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
    unitMarkers: const [],
    civilianTileMarkers: const [],
  );
}

ct_models.Game _gameWithNoUnits() {
  return ct_models.Game(
    id: 'g',
    worldState: ct_models.WorldState(
      turnState: const ct_models.TurnState(
        phase: ct_models.TurnPhase.orders,
        turnNumber: 1,
      ),
      oldWorld: const ct_models.RegionData(
        provinces: [
          ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
        ],
        units: [],
      ),
      newWorld: const ct_models.RegionData(provinces: [], units: []),
    ),
    players: const [
      ct_models.Player(
        id: 'gp1',
        displayName: 'Human',
        isHuman: true,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

PlayerView _emptyPlayerView(String playerId) {
  return PlayerView(
    playerId: playerId,
    player: ct_models.Player(
      id: playerId,
      displayName: 'P',
      isHuman: true,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: const <String, VisibilityLevel>{},
    prospectedTiles: const <String>{},
    diplomacyByOtherId: const {},
  );
}
