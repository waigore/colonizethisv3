/// Shared below-quota zero-NW lock-recovery seller Game scaffold for regiment
/// build-input feedstock extraction and producible-improvement-input pins
/// (Refs #2847 / #4084).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Seller / GP id used by below-quota zero-NW H8 extraction pins.
const String h8BelowQuotaSellerId = 'gp1';

/// Grain resource tile (lexicographically before wool) for extraction pins.
const String h8BelowQuotaGrainTile = 'oldWorld|p0|0|0';

/// Wool regiment-build-input feedstock tile for extraction pins.
const String h8BelowQuotaWoolTile = 'oldWorld|p0|1|0';

/// Timber-over-grain improvement-input seller map (Refs #2847 H8-extraction).
const Map<String, String> h8BelowQuotaTimberImprovementInputResources = {
  h8BelowQuotaGrainTile: 'grain',
  'oldWorld|p0|1|0': 'timber',
  'oldWorld|p0|2|0': 'wool',
};

/// Grain + timber stageable seller map (fabric gate inactive; Refs #2847 S7-D).
const Map<String, String> h8BelowQuotaStageableImprovementInputResources = {
  h8BelowQuotaGrainTile: 'grain',
  'oldWorld|p0|2|0': 'timber',
};

/// Builds a below-quota zero-NW lock-recovery seller with configurable OW
/// province count, treasury, stockpile, units, resources, and tile state.
Game belowQuotaZeroNwSellerGame({
  required int owOwned,
  required int treasury,
  int newWorldOwned = 0,
  Stockpile stockpile = const Stockpile(),
  List<Unit> extraUnits = const [],
  Map<String, String> resourceByTileKey = const {
    h8BelowQuotaGrainTile: 'grain',
    h8BelowQuotaWoolTile: 'wool',
  },
  TileMapState? tileState,
}) {
  final provinces = List.generate(
    owOwned,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kRegionOldWorld,
      ownerId: h8BelowQuotaSellerId,
    ),
  );
  final newWorldProvinces = List.generate(
    newWorldOwned,
    (i) => Province(
      id: 'newWorld|n$i',
      regionId: kRegionNewWorld,
      ownerId: h8BelowQuotaSellerId,
    ),
  );
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: extraUnits),
      newWorld: RegionData(provinces: newWorldProvinces),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: [
      Player(
        id: h8BelowQuotaSellerId,
        displayName: 'GP',
        isHuman: false,
        treasury: treasury,
        stockpile: stockpile,
      ),
    ],
  );
}

/// Builder [PlayerView] for selecting work orders on [h8BelowQuotaSellerId]'s
/// owned province `oldWorld|p0`.
PlayerView belowQuotaSellerBuilderView(Game game) {
  return PlayerView(
    playerId: h8BelowQuotaSellerId,
    player: game.players.single,
    ownUnitsById: {
      'b1': Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: h8BelowQuotaSellerId,
        locationProvinceId: 'oldWorld|p0',
      ),
    },
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

/// Active below-quota gate with recovered treasury unless [treasury] is set.
Game belowQuotaActiveGateSellerGame({
  int? treasury,
  int owOwned = 5,
  int newWorldOwned = 0,
  Stockpile stockpile = const Stockpile(),
  List<Unit> extraUnits = const [],
  Map<String, String> resourceByTileKey = const {
    h8BelowQuotaGrainTile: 'grain',
    h8BelowQuotaWoolTile: 'wool',
  },
  TileMapState? tileState,
}) {
  return belowQuotaZeroNwSellerGame(
    owOwned: owOwned,
    treasury: treasury ?? cheapestRegimentBuildTreasuryCost(),
    newWorldOwned: newWorldOwned,
    stockpile: stockpile,
    extraUnits: extraUnits,
    resourceByTileKey: resourceByTileKey,
    tileState: tileState,
  );
}

/// Peasant levy owned by [h8BelowQuotaSellerId] at `oldWorld|p0`.
Unit belowQuotaPeasantLevyUnit() => Unit(
  id: 'r1',
  type: 'peasant_levies',
  ownerId: h8BelowQuotaSellerId,
  locationProvinceId: 'oldWorld|p0',
);

/// Grain + wool `build_improvement` suggestions for Builder `b1`.
List<WorkOrder> belowQuotaGrainWoolBuildSuggestions() => const [
  WorkOrder(
    unitId: 'b1',
    target: kWorkTargetBuildImprovement,
    targetTileKey: h8BelowQuotaGrainTile,
  ),
  WorkOrder(
    unitId: 'b1',
    target: kWorkTargetBuildImprovement,
    targetTileKey: h8BelowQuotaWoolTile,
  ),
];
