import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_narrow_detail_overlay.dart';
import 'package:colonizethis_app/features/game/flame/overlays/game_map_province_detail_side_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'province_shortcut_host_emit_fixtures.dart';

const String kConsulateShortcutGameId = 'g_consulate_shortcut';
const String kConsulateShortcutHumanId = 'gp1';
const String kConsulateShortcutMinorId = 'minor1';
const String kConsulateShortcutProvinceId = 'oldWorld|p1';
const String kConsulateShortcutTileKey = 'oldWorld|p1|0|0';

final MapTopology consulateShortcutTopology =
    provinceShortcutHostCombinedTopology(includeSea: false);

final Map<String, TileMapResult> consulateShortcutTileMaps =
    provinceShortcutHostTileMapByRegion(
      terrainGrid: const [
        [TerrainType.hills],
      ],
      resourceGrid: const [
        [null],
      ],
    );

class ConsulateShortcutGameService extends GameService {
  ConsulateShortcutGameService(super.box, super.adapter);

  @override
  GameMapData? getMapData(String gameId) {
    if (gameId != kConsulateShortcutGameId) return null;
    return (
      combinedTopology: consulateShortcutTopology,
      tileMapByRegion: consulateShortcutTileMaps,
      topologyByRegion: {'oldWorld': consulateShortcutTopology},
      warpLinks: null,
    );
  }
}

Game consulateShortcutGame({bool expertise = true}) => Game(
  id: kConsulateShortcutGameId,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: const [
        Province(
          id: kConsulateShortcutProvinceId,
          regionId: 'oldWorld',
          ownerId: kConsulateShortcutMinorId,
          displayName: 'Bavaria Province',
        ),
      ],
      units: const [],
    ),
    newWorld: const RegionData(provinces: [], units: []),
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        kConsulateShortcutProvinceId: [kConsulateShortcutTileKey],
      },
    },
    playerVisibilityByTile: const {
      kConsulateShortcutHumanId: {kConsulateShortcutTileKey: 'fullyVisible'},
    },
  ),
  players: [
    Player(
      id: kConsulateShortcutHumanId,
      displayName: 'Human',
      isHuman: true,
      treasury: 5000,
      techUnlocked: expertise
          ? const {kTechIdDiplomaticExpertise: true}
          : const {},
    ),
  ],
  minorNations: const [
    MinorNation(id: kConsulateShortcutMinorId, displayName: 'Bavaria'),
  ],
  tribes: const [],
);

RegionMapViewData consulateShortcutRegion() => RegionMapViewData(
  regionId: 'oldWorld',
  width: 1,
  height: 1,
  cellSize: 16,
  cells: const [
    CellViewData(
      x: 0,
      y: 0,
      regionCellId: 'p1',
      isSea: false,
      terrainType: TerrainType.hills,
      ownerFactionId: kConsulateShortcutMinorId,
      provinceDisplayName: 'Bavaria Province',
      visibility: TileVisibility.visible,
    ),
  ],
  capitalMarkers: const [],
  portMarkers: const [],
  factionColors: const {},
  greatPowerFactionIds: const {kConsulateShortcutHumanId},
  terrainColors: const {},
  provincePoliticalOwnerByPrefixedProvinceId: const {
    kConsulateShortcutProvinceId: kConsulateShortcutMinorId,
  },
);

const DiplomaticOrder kConsulateShortcutOrder = DiplomaticOrder(
  type: DiplomaticOrderType.establishOverture,
  targetFactionId: kConsulateShortcutMinorId,
  overtureStage: OvertureStage.tradeConsulate,
);

Orders consulateShortcutPending() => const Orders(
  diplomaticOrdersByPlayerId: {
    kConsulateShortcutHumanId: [kConsulateShortcutOrder],
  },
);

typedef ConsulateShortcutHostCase = ({bool wide, Size size, Type type});

const List<ConsulateShortcutHostCase> kConsulateShortcutHosts = [
  (wide: true, size: Size(720, 720), type: GameMapProvinceDetailSidePanel),
  (wide: false, size: Size(360, 640), type: GameMapNarrowDetailOverlaySlot),
];
