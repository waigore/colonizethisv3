import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        PlayerView,
        VisibilityLevel,
        buildPlayerView,
        getValidWorkOrderTileKeysWithVisibility,
        kWorkTargetBuildImprovement;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

/// Expected `provinceBuildImprovementActionState(...).enabled` per **pipeline contract A**
/// ([SPEC/program/order-suggestions.md](../../SPEC/program/order-suggestions.md) § Province Tile
/// `Build improvement` shortcut enablement): same predicate as
/// [GameMapAreaStateLogic.provinceBuildImprovementActionState] — any human Builder whose allowed
/// targets include `build_improvement` has `selectedTileKey` in
/// `getValidWorkOrderTileKeysWithVisibility` for the same `(game, topology, view, orders, tileMap)`.
bool _expectedBuildImprovementEnabledFromPipeline({
  required ct_models.Game game,
  required String humanPlayerId,
  required String selectedTileKey,
  required PlayerView playerView,
  required MapTopology? topology,
  required ct_models.Orders currentOrders,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (topology == null) return false;
  final allUnits = <ct_models.Unit>[
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  final builderUnits = allUnits
      .where((unit) => unit.ownerId == humanPlayerId)
      .where(
        (unit) =>
            workOrderTargetsByUnitType[unit.type]?.contains(
              kWorkTargetBuildImprovement,
            ) ??
            false,
      )
      .toList();
  if (builderUnits.isEmpty) return false;
  return builderUnits.any((builder) {
    final valid = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: playerView,
      unitId: builder.id,
      workTarget: kWorkTargetBuildImprovement,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
    return valid.contains(selectedTileKey);
  });
}

void _expectPortFleetMarkersMatchTownPortDrawables(RegionMapViewData region) {
  for (final m in region.fleetTileMarkers) {
    if (!m.locationScopeKey.startsWith('port:')) {
      continue;
    }
    final localProv = m.locationScopeKey.substring(5).split('|').last;
    final towns = region.townMarkers
        .where((t) => t.provinceId == localProv && t.isPort)
        .toList();
    expect(towns, isNotEmpty, reason: 'port town for $localProv');
    final town = towns.single;
    expect(m.x, town.portIconX, reason: 'fleet x vs port icon $localProv');
    expect(m.y, town.portIconY, reason: 'fleet y vs port icon $localProv');
  }
}

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
              provinces: const [
                ct_models.Province(
                  id: selectedProvinceId,
                  regionId: 'oldWorld',
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
          tribes: const [],
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
          final expected = _expectedBuildImprovementEnabledFromPipeline(
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
          final expected = _expectedBuildImprovementEnabledFromPipeline(
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
          final expected = _expectedBuildImprovementEnabledFromPipeline(
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
