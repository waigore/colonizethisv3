// Fixtures and expectation helpers for
// game_map_area_state_logic_prospect_and_explore_test.dart (Refs #4680).

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter_test/flutter_test.dart';

const kProspectExploreHumanPlayerId = 'gp1';
const kProspectExploreSelectedTileKey = 'oldWorld|p1|0|0';
const kProspectExploreSelectedProvinceId = 'oldWorld|p1';
const kProspectExploreTribe = ct_models.Tribe(id: 'tribe1', displayName: 'Tribe');

ct_models.Game prospectExploreMakeGame({
  bool includeExplorer = true,
  bool includeProspectedTile = false,
  String? resourceOverride,
  String? provinceOwnerId,
  List<ct_models.Tribe> tribes = const [],
  List<ct_models.OvertureState> overtureStates = const [],
}) {
  final resourceByTileKey = resourceOverride != null
      ? {kProspectExploreSelectedTileKey: resourceOverride}
      : const {kProspectExploreSelectedTileKey: 'iron'};
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
            id: kProspectExploreSelectedProvinceId,
            regionId: 'oldWorld',
            ownerId: provinceOwnerId,
          ),
        ],
        units: includeExplorer
            ? [
                ct_models.Unit(
                  id: 'u_explorer',
                  type: ct_models.kUnitTypeExplorer,
                  ownerId: kProspectExploreHumanPlayerId,
                  locationProvinceId: kProspectExploreSelectedProvinceId,
                  tileKey: kProspectExploreSelectedTileKey,
                  status: ct_models.UnitStatus.idle,
                ),
              ]
            : const [],
      ),
      newWorld: const ct_models.RegionData(provinces: [], units: []),
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: includeProspectedTile
          ? const {
              kProspectExploreHumanPlayerId: {kProspectExploreSelectedTileKey},
            }
          : const {},
    ),
    players: const [
      ct_models.Player(
        id: kProspectExploreHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
      ),
    ],
    minorNations: const [],
    tribes: tribes,
    overtureStates: overtureStates,
  );
}

({bool showIcon, bool enabled, bool hasMatchingUnits}) prospectExploreState({
  required ct_models.Game game,
  required VisibilityLevel visibility,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  return GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
    game: game,
    humanPlayerId: kProspectExploreHumanPlayerId,
    selectedTileKey: kProspectExploreSelectedTileKey,
    playerView: PlayerView(
      playerId: kProspectExploreHumanPlayerId,
      player: const ct_models.Player(
        id: kProspectExploreHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
      ),
      ownUnitsById: {},
      provincesById: {},
      visibilityByTile: {kProspectExploreSelectedTileKey: visibility},
      prospectedTiles: {},
      diplomacyByOtherId: {},
    ),
    topology: null,
    currentOrders: const ct_models.Orders(),
    tileMapByRegion: tileMapByRegion,
  );
}

void expectProspectExplore({
  required String name,
  required ct_models.Game game,
  required VisibilityLevel visibility,
  required bool showIcon,
  required bool enabled,
  bool? hasMatchingUnits,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  test(name, () {
    final state = prospectExploreState(
      game: game,
      visibility: visibility,
      tileMapByRegion: tileMapByRegion,
    );
    expect(state.showIcon, showIcon);
    expect(state.enabled, enabled);
    if (hasMatchingUnits != null) {
      expect(state.hasMatchingUnits, hasMatchingUnits);
    }
  });
}

ct_models.Game get prospectExploreExploreGame => ct_models.Game(
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
          ownerId: kProspectExploreHumanPlayerId,
          locationProvinceId: 'oldWorld|p1',
          tileKey: kProspectExploreSelectedTileKey,
        ),
      ],
    ),
    newWorld: const ct_models.RegionData(),
  ),
  players: const [
    ct_models.Player(
      id: kProspectExploreHumanPlayerId,
      displayName: 'Human',
      isHuman: true,
    ),
  ],
);

RegionMapViewData prospectExploreRegionWithCells(List<TileVisibility> vis) =>
    RegionMapViewData(
      regionId: 'oldWorld',
      width: 2,
      height: 1,
      cellSize: 16,
      cells: [
        for (var i = 0; i < vis.length; i++)
          CellViewData(
            x: i,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            visibility: vis[i],
          ),
      ],
      capitalMarkers: const [],
      portMarkers: const [],
      factionColors: const {},
      greatPowerFactionIds: const {},
      terrainColors: const {},
      unitMarkers: const [],
    );

({bool showIcon, bool enabled, bool hasMatchingUnits}) prospectExploreAction(
  ct_models.Game g,
  RegionMapViewData region,
) =>
    GameMapAreaStateLogicProvinceActions.provinceExploreActionState(
      game: g,
      humanPlayerId: kProspectExploreHumanPlayerId,
      selectedTileKey: kProspectExploreSelectedTileKey,
      selectedRegion: region,
      cachedExploreEligibleTileKeys: const {'oldWorld|p1|1|0'},
    );

RegionMapViewData get prospectExplorePartialRegion => prospectExploreRegionWithCells(
  const [TileVisibility.fogged, TileVisibility.unrevealed],
);
