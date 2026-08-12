// Shared flagged below-quota zero-NW lock-recovery seller Game fixtures for
// EXPAND feedstock acquisition pins (Refs #4310 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';

const String kExpandFeedstockSellerId = 'gp1';
const String kExpandFeedstockOldWorld = 'oldWorld';

const String kExpandFeedstockGrainTile = 'oldWorld|p0|0|0';
const String kExpandFeedstockWoolTile = 'oldWorld|p0|2|0';

const Map<String, String> kExpandFeedstockDefaultResourceByTileKey = {
  kExpandFeedstockGrainTile: 'grain',
  kExpandFeedstockWoolTile: 'wool',
};

List<Province> expandFeedstockSellerBaseProvinces() {
  return List.generate(
    5,
    (i) => Province(
      id: 'oldWorld|p$i',
      regionId: kExpandFeedstockOldWorld,
      ownerId: kExpandFeedstockSellerId,
    ),
  );
}

Game buildExpandFeedstockAcquisitionTargetGame({
  Map<String, String> resourceByTileKey =
      kExpandFeedstockDefaultResourceByTileKey,
  List<Province> extraOldWorld = const [],
  List<Province> extraNewWorld = const [],
  TileMapState? tileState,
}) {
  return Game(
    id: 'g-2847-expand-feedstock-acquisition',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [...expandFeedstockSellerBaseProvinces(), ...extraOldWorld],
      ),
      newWorld: RegionData(provinces: extraNewWorld),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: const [
      Player(
        id: kExpandFeedstockSellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: 0,
        stockpile: Stockpile(),
      ),
    ],
  );
}

Game buildExpandFeedstockDeclareWarBiasGame({
  required Map<String, String> resourceByTileKey,
  required List<Province> minorProvinces,
  required List<MinorNation> minorNations,
  int sellerTreasury = 0,
}) {
  return Game(
    id: 'g-2847-expand-feedstock-declare-war-bias',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [...expandFeedstockSellerBaseProvinces(), ...minorProvinces],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
      tileState: TileMapState(),
    ),
    players: [
      Player(
        id: kExpandFeedstockSellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: sellerTreasury,
        stockpile: const Stockpile(),
      ),
    ],
    minorNations: minorNations,
  );
}
