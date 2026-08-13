import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'game_map_area_state_logic_test_support.dart';

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    group('provinceBuildImprovementActionState', () {
      const humanPlayerId = 'gp1';
      const selectedTileKey = 'oldWorld|p1|0|0';
      const selectedProvinceId = 'oldWorld|p1';
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      final tileMapByRegion = <String, TileMapResult>{
        'oldWorld': TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['p1'],
          ],
          terrainGrid: const [
            [TerrainType.plains],
          ],
          resourceGrid: const [
            [Resource.grain],
          ],
        ),
      };

      PlayerView makePlayerView() => PlayerView(
        playerId: humanPlayerId,
        player: const ct_models.Player(
          id: humanPlayerId,
          displayName: 'Human',
          isHuman: true,
        ),
        ownUnitsById: {},
        provincesById: {},
        visibilityByTile: const {
          selectedTileKey: VisibilityLevel.fullyVisible,
        },
        prospectedTiles: {},
        diplomacyByOtherId: {},
      );

      ct_models.Game makeGame({
        bool includeBuilder = true,
        bool includeResource = true,
        Map<String, bool>? techUnlocked,
        String? ownerId,
        Map<String, int>? stockpileQuantities,
        bool circularSaw = false,
      }) {
        final stockpile = ct_models.Stockpile(
          quantities:
              stockpileQuantities ??
              const {'lumber': 999, 'castIron': 999},
        );
        return ct_models.Game(
          id: 'g',
          worldState: ct_models.WorldState(
            turnState: const ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(
              provinces: [
                ct_models.Province(
                  id: selectedProvinceId,
                  regionId: 'oldWorld',
                  ownerId: ownerId,
                ),
              ],
              units: includeBuilder
                  ? [
                      ct_models.Unit(
                        id: 'u_builder',
                        type: ct_models.kUnitTypeBuilder,
                        ownerId: humanPlayerId,
                        locationProvinceId: selectedProvinceId,
                        tileKey: selectedTileKey,
                        status: ct_models.UnitStatus.idle,
                      ),
                    ]
                  : const [],
            ),
            newWorld: const ct_models.RegionData(provinces: [], units: []),
            resourceByTileKey: includeResource
                ? const {selectedTileKey: 'grain'}
                : const {},
            tileKeysByRegionAndProvince: ownerId == null
                ? const {}
                : {
                    'oldWorld': {
                      selectedProvinceId: [selectedTileKey],
                    },
                  },
            tileState: ownerId == null
                ? const ct_models.TileMapState()
                : ct_models.TileMapState(
                    improvementByTile: {selectedTileKey: 0},
                  ),
            playerVisibilityByTile: ownerId == null
                ? const {}
                : {
                    humanPlayerId: {selectedTileKey: 'fullyVisible'},
                  },
          ),
          players: [
            ct_models.Player(
              id: humanPlayerId,
              displayName: 'Human',
              isHuman: true,
              capitalProvinceId: ownerId == null ? null : selectedProvinceId,
              stockpile: stockpile,
              techUnlocked: circularSaw
                  ? const {kTechIdCircularSaw: true}
                  : techUnlocked,
            ),
          ],
          minorNations: const [],
          tribes: const [],
        );
      }

      ({bool showIcon, bool enabled, bool hasBuilderUnits}) buildState({
        required ct_models.Game game,
        MapTopology? topology,
        PlayerView? playerView,
      }) {
        return GameMapAreaStateLogicProvinceActions.provinceBuildImprovementActionState(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: playerView ?? makePlayerView(),
          topology: topology,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: tileMapByRegion,
        );
      }

      void expectMatchesPipeline({
        required ct_models.Game game,
        required MapTopology? topologyArg,
        required PlayerView view,
        required bool expectEnabled,
      }) {
        final expected = expectedBuildImprovementEnabledFromPipeline(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: view,
          topology: topologyArg,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: tileMapByRegion,
        );
        final state = buildState(
          game: game,
          topology: topologyArg,
          playerView: view,
        );
        expect(state.enabled, expected);
        expect(expected, expectEnabled);
      }

      test('shows icon for improvable tile with builder units', () {
        final state = buildState(game: makeGame());
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
        expect(state.hasBuilderUnits, isTrue);
      });

      test('hides icon when tile has no resource', () {
        final state = buildState(
          game: makeGame(includeResource: false, techUnlocked: const {}),
          topology: topology,
        );
        expect(state.showIcon, isFalse);
        expect(state.enabled, isFalse);
      });

      test('shows disabled icon when no builder units exist', () {
        final state = buildState(
          game: makeGame(includeBuilder: false),
          topology: topology,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
        expect(state.hasBuilderUnits, isFalse);
      });

      // Pipeline contract (A), Refs #1990 — SPEC/program/order-suggestions.md §
      // Province Tile `Build improvement` shortcut enablement.
      test(
        'enabled matches getValidWorkOrderTileKeysWithVisibility pipeline when topology null',
        () {
          expectMatchesPipeline(
            game: makeGame(),
            topologyArg: null,
            view: makePlayerView(),
            expectEnabled: false,
          );
        },
      );

      test(
        'enabled matches pipeline for assignable grain tile with topology and materials',
        () {
          final richGame = makeGame(
            ownerId: humanPlayerId,
            stockpileQuantities: const {'lumber': 10, 'castIron': 10},
            circularSaw: true,
          );
          expectMatchesPipeline(
            game: richGame,
            topologyArg: topology,
            view: buildPlayerView(richGame, topology, humanPlayerId),
            expectEnabled: true,
          );
        },
      );

      test(
        'enabled matches pipeline when materials are insufficient for build_improvement',
        () {
          final brokeGame = makeGame(
            ownerId: humanPlayerId,
            stockpileQuantities: const {},
            circularSaw: true,
          );
          expectMatchesPipeline(
            game: brokeGame,
            topologyArg: topology,
            view: buildPlayerView(brokeGame, topology, humanPlayerId),
            expectEnabled: false,
          );
        },
      );
    });
  });
}
