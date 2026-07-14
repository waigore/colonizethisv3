import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'support/game_map_area_state_logic_test_support.dart';

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    group('provinceProspectActionState', () {
      const humanPlayerId = 'gp1';
      const selectedTileKey = 'oldWorld|p1|0|0';
      const selectedProvinceId = 'oldWorld|p1';

      ct_models.Game makeGame({
        bool includeExplorer = true,
        bool includeProspectedTile = false,
        bool includeMineralResource = true,
        String? resourceOverride,
        String? provinceOwnerId,
        List<ct_models.Tribe> tribes = const [],
        List<ct_models.OvertureState> overtureStates = const [],
      }) {
        final Map<String, String> resourceByTileKey;
        if (resourceOverride != null) {
          resourceByTileKey = {selectedTileKey: resourceOverride};
        } else if (includeMineralResource) {
          resourceByTileKey = const {selectedTileKey: 'iron'};
        } else {
          resourceByTileKey = const {};
        }
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
                  ownerId: provinceOwnerId,
                ),
              ],
              units: includeExplorer
                  ? [
                      ct_models.Unit(
                        id: 'u_explorer',
                        type: ct_models.kUnitTypeExplorer,
                        ownerId: humanPlayerId,
                        locationProvinceId: selectedProvinceId,
                        tileKey: selectedTileKey,
                        status: ct_models.UnitStatus.idle,
                      ),
                    ]
                  : const [],
            ),
            newWorld: const ct_models.RegionData(provinces: [], units: []),
            resourceByTileKey: resourceByTileKey,
            playerProspectedTiles: includeProspectedTile
                ? const {
                    humanPlayerId: {selectedTileKey},
                  }
                : const {},
          ),
          players: const [
            ct_models.Player(
              id: humanPlayerId,
              displayName: 'Human',
              isHuman: true,
            ),
          ],
          minorNations: const [],
          tribes: tribes,
          overtureStates: overtureStates,
        );
      }

      PlayerView makePlayerView({required VisibilityLevel tileVisibility}) {
        return PlayerView(
          playerId: humanPlayerId,
          player: const ct_models.Player(
            id: humanPlayerId,
            displayName: 'Human',
            isHuman: true,
          ),
          ownUnitsById: {},
          provincesById: {},
          visibilityByTile: {selectedTileKey: tileVisibility},
          prospectedTiles: {},
          diplomacyByOtherId: {},
        );
      }

      test('shows enabled icon for visible, unprospected mineral tile', () {
        final state = GameMapAreaStateLogic.provinceProspectActionState(
          game: makeGame(),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(
            tileVisibility: VisibilityLevel.fullyVisible,
          ),
          topology: null,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: null,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isTrue);
        expect(state.hasExplorerUnits, isTrue);
      });

      test('hides icon when selected tile already prospected', () {
        final state = GameMapAreaStateLogic.provinceProspectActionState(
          game: makeGame(includeProspectedTile: true),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(tileVisibility: VisibilityLevel.fogged),
          topology: null,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: null,
        );
        expect(state.showIcon, isFalse);
        expect(state.enabled, isFalse);
        expect(state.hasExplorerUnits, isFalse);
      });

      test('shows disabled icon when human has zero explorer units', () {
        final state = GameMapAreaStateLogic.provinceProspectActionState(
          game: makeGame(includeExplorer: false),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(
            tileVisibility: VisibilityLevel.fullyVisible,
          ),
          topology: null,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: null,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
        expect(state.hasExplorerUnits, isFalse);
      });

      // Refs #3753 R4/R4b: prospect inside a Minor/Tribe province requires a
      // Consulate (or higher). Without it the inline action must be shown
      // disabled (so the overlay can surface the rejection tooltip) rather than
      // enabled-then-rejected at submission.
      test(
        'shows disabled icon for Minor/Tribe province without a Consulate',
        () {
          final state = GameMapAreaStateLogic.provinceProspectActionState(
            game: makeGame(
              provinceOwnerId: 'tribe1',
              tribes: const [
                ct_models.Tribe(id: 'tribe1', displayName: 'Tribe'),
              ],
            ),
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: makePlayerView(tileVisibility: VisibilityLevel.fogged),
            topology: null,
            currentOrders: const ct_models.Orders(),
            tileMapByRegion: null,
          );
          expect(state.showIcon, isTrue);
          expect(state.enabled, isFalse);
        },
      );

      test('shows enabled icon for Minor/Tribe province with a Consulate', () {
        final state = GameMapAreaStateLogic.provinceProspectActionState(
          game: makeGame(
            provinceOwnerId: 'tribe1',
            tribes: const [ct_models.Tribe(id: 'tribe1', displayName: 'Tribe')],
            overtureStates: const [
              ct_models.OvertureState(
                gpId: humanPlayerId,
                targetId: 'tribe1',
                stage: ct_models.OvertureStage.tradeConsulate,
              ),
            ],
          ),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(tileVisibility: VisibilityLevel.fogged),
          topology: null,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: null,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isTrue);
      });

      test('hides icon for unknown-visibility tiles', () {
        final state = GameMapAreaStateLogic.provinceProspectActionState(
          game: makeGame(),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(tileVisibility: VisibilityLevel.unknown),
          topology: null,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: null,
        );
        expect(state.showIcon, isFalse);
        expect(state.enabled, isFalse);
        expect(state.hasExplorerUnits, isFalse);
      });

      test(
        'hides prospect shortcut for wool on hills when tile map marks hills',
        () {
          final tileMapByRegion = <String, TileMapResult>{
            'oldWorld': TileMapResult(
              width: 1,
              height: 1,
              grid: const [
                ['p1'],
              ],
              terrainGrid: const [
                [TerrainType.hills],
              ],
              resourceGrid: const [
                [Resource.wool],
              ],
            ),
          };
          final state = GameMapAreaStateLogic.provinceProspectActionState(
            game: makeGame(resourceOverride: 'wool'),
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: makePlayerView(
              tileVisibility: VisibilityLevel.fullyVisible,
            ),
            topology: null,
            currentOrders: const ct_models.Orders(),
            tileMapByRegion: tileMapByRegion,
          );
          expect(state.showIcon, isFalse);
          expect(state.enabled, isFalse);
          expect(state.hasExplorerUnits, isFalse);
        },
      );
    });

    group('provinceBuildImprovementActionState', () {
      const humanPlayerId = 'gp1';
      const selectedTileKey = 'oldWorld|p1|0|0';
      const selectedProvinceId = 'oldWorld|p1';

      ct_models.Game makeGame({
        bool includeBuilder = true,
        bool includeResource = true,
        Map<String, bool>? techUnlocked,
      }) {
        return ct_models.Game(
          id: 'g',
          worldState: ct_models.WorldState(
            turnState: const ct_models.TurnState(
              phase: ct_models.TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: ct_models.RegionData(
              provinces: const [
                ct_models.Province(
                  id: selectedProvinceId,
                  regionId: 'oldWorld',
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
          ),
          players: [
            ct_models.Player(
              id: humanPlayerId,
              displayName: 'Human',
              isHuman: true,
              stockpile: const ct_models.Stockpile(
                quantities: {'lumber': 999, 'castIron': 999},
              ),
              techUnlocked: techUnlocked,
            ),
          ],
          minorNations: const [],
          tribes: const [],
        );
      }

      PlayerView makePlayerView() {
        return PlayerView(
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
      }

      final topology = const MapTopology(
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

      test('shows icon for improvable tile with builder units', () {
        final state = GameMapAreaStateLogic.provinceBuildImprovementActionState(
          game: makeGame(),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(),
          topology: null,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: tileMapByRegion,
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
        expect(state.hasBuilderUnits, isTrue);
      });

      test('hides icon when tile has no resource', () {
        final state = GameMapAreaStateLogic.provinceBuildImprovementActionState(
          game: makeGame(includeResource: false, techUnlocked: const {}),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(),
          topology: topology,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: tileMapByRegion,
        );
        expect(state.showIcon, isFalse);
        expect(state.enabled, isFalse);
      });

      test('shows disabled icon when no builder units exist', () {
        final state = GameMapAreaStateLogic.provinceBuildImprovementActionState(
          game: makeGame(includeBuilder: false),
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          playerView: makePlayerView(),
          topology: topology,
          currentOrders: const ct_models.Orders(),
          tileMapByRegion: tileMapByRegion,
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
          final game = makeGame();
          final state =
              GameMapAreaStateLogic.provinceBuildImprovementActionState(
                game: game,
                humanPlayerId: humanPlayerId,
                selectedTileKey: selectedTileKey,
                playerView: makePlayerView(),
                topology: null,
                currentOrders: const ct_models.Orders(),
                tileMapByRegion: tileMapByRegion,
              );
          final expected = expectedBuildImprovementEnabledFromPipeline(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: makePlayerView(),
            topology: null,
            currentOrders: const ct_models.Orders(),
            tileMapByRegion: tileMapByRegion,
          );
          expect(state.enabled, expected);
          expect(state.enabled, isFalse);
        },
      );

      test(
        'enabled matches pipeline for assignable grain tile with topology and materials',
        () {
          const provinceId = selectedProvinceId;
          final richGame = ct_models.Game(
            id: 'g',
            worldState: ct_models.WorldState(
              turnState: const ct_models.TurnState(
                phase: ct_models.TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: ct_models.RegionData(
                provinces: [
                  ct_models.Province(
                    id: provinceId,
                    regionId: 'oldWorld',
                    ownerId: humanPlayerId,
                  ),
                ],
                units: [
                  ct_models.Unit(
                    id: 'u_builder',
                    type: ct_models.kUnitTypeBuilder,
                    ownerId: humanPlayerId,
                    locationProvinceId: provinceId,
                    tileKey: selectedTileKey,
                    status: ct_models.UnitStatus.idle,
                  ),
                ],
              ),
              newWorld: const ct_models.RegionData(provinces: [], units: []),
              resourceByTileKey: const {selectedTileKey: 'grain'},
              tileKeysByRegionAndProvince: {
                'oldWorld': {
                  provinceId: [selectedTileKey],
                },
              },
              tileState: ct_models.TileMapState(
                improvementByTile: {selectedTileKey: 0},
              ),
              playerVisibilityByTile: {
                humanPlayerId: {selectedTileKey: 'fullyVisible'},
              },
            ),
            players: [
              ct_models.Player(
                id: humanPlayerId,
                displayName: 'Human',
                isHuman: true,
                capitalProvinceId: provinceId,
                stockpile: const ct_models.Stockpile(
                  quantities: {'lumber': 10, 'castIron': 10},
                ),
                techUnlocked: const {kTechIdCircularSaw: true},
              ),
            ],
            minorNations: const [],
            tribes: const [],
          );
          final richView = buildPlayerView(richGame, topology, humanPlayerId);
          const orders = ct_models.Orders();
          final expected = expectedBuildImprovementEnabledFromPipeline(
            game: richGame,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: richView,
            topology: topology,
            currentOrders: orders,
            tileMapByRegion: tileMapByRegion,
          );
          final state =
              GameMapAreaStateLogic.provinceBuildImprovementActionState(
                game: richGame,
                humanPlayerId: humanPlayerId,
                selectedTileKey: selectedTileKey,
                playerView: richView,
                topology: topology,
                currentOrders: orders,
                tileMapByRegion: tileMapByRegion,
              );
          expect(state.enabled, expected);
          expect(expected, isTrue);
        },
      );

      test(
        'enabled matches pipeline when materials are insufficient for build_improvement',
        () {
          const provinceId = selectedProvinceId;
          final brokeGame = ct_models.Game(
            id: 'g',
            worldState: ct_models.WorldState(
              turnState: const ct_models.TurnState(
                phase: ct_models.TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: ct_models.RegionData(
                provinces: [
                  ct_models.Province(
                    id: provinceId,
                    regionId: 'oldWorld',
                    ownerId: humanPlayerId,
                  ),
                ],
                units: [
                  ct_models.Unit(
                    id: 'u_builder',
                    type: ct_models.kUnitTypeBuilder,
                    ownerId: humanPlayerId,
                    locationProvinceId: provinceId,
                    tileKey: selectedTileKey,
                    status: ct_models.UnitStatus.idle,
                  ),
                ],
              ),
              newWorld: const ct_models.RegionData(provinces: [], units: []),
              resourceByTileKey: const {selectedTileKey: 'grain'},
              tileKeysByRegionAndProvince: {
                'oldWorld': {
                  provinceId: [selectedTileKey],
                },
              },
              tileState: ct_models.TileMapState(
                improvementByTile: {selectedTileKey: 0},
              ),
              playerVisibilityByTile: {
                humanPlayerId: {selectedTileKey: 'fullyVisible'},
              },
            ),
            players: [
              ct_models.Player(
                id: humanPlayerId,
                displayName: 'Human',
                isHuman: true,
                capitalProvinceId: provinceId,
                stockpile: const ct_models.Stockpile(quantities: {}),
                techUnlocked: const {kTechIdCircularSaw: true},
              ),
            ],
            minorNations: const [],
            tribes: const [],
          );
          final brokeView = buildPlayerView(brokeGame, topology, humanPlayerId);
          const orders = ct_models.Orders();
          final expected = expectedBuildImprovementEnabledFromPipeline(
            game: brokeGame,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            playerView: brokeView,
            topology: topology,
            currentOrders: orders,
            tileMapByRegion: tileMapByRegion,
          );
          final state =
              GameMapAreaStateLogic.provinceBuildImprovementActionState(
                game: brokeGame,
                humanPlayerId: humanPlayerId,
                selectedTileKey: selectedTileKey,
                playerView: brokeView,
                topology: topology,
                currentOrders: orders,
                tileMapByRegion: tileMapByRegion,
              );
          expect(state.enabled, expected);
          expect(expected, isFalse);
        },
      );
    });

    group('provinceExploreActionState', () {
      const humanPlayerId = 'gp1';
      const selectedTileKey = 'oldWorld|p1|0|0';
      final game = ct_models.Game(
        id: 'g',
        worldState: ct_models.WorldState(
          turnState: const ct_models.TurnState(
            phase: ct_models.TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: ct_models.RegionData(
            provinces: const [
              ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
            ],
            units: [
              ct_models.Unit(
                id: 'u_explorer',
                type: ct_models.kUnitTypeExplorer,
                ownerId: humanPlayerId,
                locationProvinceId: 'oldWorld|p1',
                tileKey: selectedTileKey,
              ),
            ],
          ),
          newWorld: const ct_models.RegionData(),
        ),
        players: const [
          ct_models.Player(
            id: humanPlayerId,
            displayName: 'Human',
            isHuman: true,
          ),
        ],
      );

      final partiallyRevealedRegion = RegionMapViewData(
        regionId: 'oldWorld',
        width: 2,
        height: 1,
        cellSize: 16,
        cells: const [
          CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            visibility: TileVisibility.fogged,
          ),
          CellViewData(
            x: 1,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            visibility: TileVisibility.unrevealed,
          ),
        ],
        capitalMarkers: const [],
        portMarkers: const [],
        factionColors: const {},
        greatPowerFactionIds: const {},
        terrainColors: const {},
        unitMarkers: const [],
      );

      test(
        'shows enabled icon in partially revealed province with cached target',
        () {
          final state = GameMapAreaStateLogic.provinceExploreActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: selectedTileKey,
            selectedRegion: partiallyRevealedRegion,
            cachedExploreEligibleTileKeys: const {'oldWorld|p1|1|0'},
          );
          expect(state.showIcon, isTrue);
          expect(state.enabled, isTrue);
        },
      );

      test('hides icon when province is fully revealed', () {
        final fullyRevealedRegion = RegionMapViewData(
          regionId: 'oldWorld',
          width: 2,
          height: 1,
          cellSize: 16,
          cells: const [
            CellViewData(
              x: 0,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              visibility: TileVisibility.fogged,
            ),
            CellViewData(
              x: 1,
              y: 0,
              regionCellId: 'p1',
              isSea: false,
              visibility: TileVisibility.fogged,
            ),
          ],
          capitalMarkers: const [],
          portMarkers: const [],
          factionColors: const {},
          greatPowerFactionIds: const {},
          terrainColors: const {},
          unitMarkers: const [],
        );
        final state = GameMapAreaStateLogic.provinceExploreActionState(
          game: game,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          selectedRegion: fullyRevealedRegion,
          cachedExploreEligibleTileKeys: const {'oldWorld|p1|1|0'},
        );
        expect(state.showIcon, isFalse);
      });

      test('shows disabled icon when no explorers exist', () {
        final noExplorerGame = game.copyWith(
          worldState: game.worldState.copyWith(
            oldWorld: ct_models.RegionData(
              provinces: game.worldState.oldWorld.provinces,
              units: const [],
            ),
          ),
        );
        final state = GameMapAreaStateLogic.provinceExploreActionState(
          game: noExplorerGame,
          humanPlayerId: humanPlayerId,
          selectedTileKey: selectedTileKey,
          selectedRegion: partiallyRevealedRegion,
          cachedExploreEligibleTileKeys: const {'oldWorld|p1|1|0'},
        );
        expect(state.showIcon, isTrue);
        expect(state.enabled, isFalse);
      });
    });
  });
}
