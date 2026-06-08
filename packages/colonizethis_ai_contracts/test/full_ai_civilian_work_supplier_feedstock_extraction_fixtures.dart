import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// Refs #2847 § H8-extraction supplier feedstock. Two-player fixture: an
// above-quota affluent supplier (`supplierFeedstockId`) and a below-quota
// zero-NW lock-recovery seller (`sellerFeedstockId`) that needs the `castIron`
// improvement input but holds none. The supplier owns an unimproved `timber`
// tile (and a `grain` tile) so the supplier-side extraction gate can route its
// Builder.
const supplierFeedstockId = 'gp1';
const sellerFeedstockId = 'gp2';

// The grain tile key is lexicographically smaller than the timber tile key, so
// ordinary build-improvement ordering (equal base score, lexicographic
// tie-break) selects grain; only the active feedstock score boost flips the
// supplier's Builder onto the timber tile.
const supplierGrainTile = 'oldWorld|s0|0|0';
const supplierTimberTile = 'oldWorld|s0|1|0';
const sellerWoolTile = 'oldWorld|p0|0|0';

/// Builds a game with a supplier owning [supplierOw] Old World provinces and a
/// seller owning [sellerOw] Old World provinces. The seller is configured (by
/// default) as an active below-quota zero-NW lock-recovery seller that needs
/// the `castIron` improvement input: recovered treasury, zero regiments, no
/// `fabric`, `lumber` on hand (so only the `castIron` improvement input is
/// missing) and an unimproved `wool` feedstock tile.
Game twoPlayerSupplierFeedstockGame({
  int supplierOw = kObserverConquestMinOwProvincesPerGp,
  int sellerOw = 5,
  int sellerTreasury = -1,
  Stockpile sellerStockpile = const Stockpile(quantities: {'lumber': 1}),
  Map<String, String> resourceByTileKey = const {
    supplierTimberTile: 'timber',
    supplierGrainTile: 'grain',
    sellerWoolTile: 'wool',
  },
  TileMapState? tileState,
  List<Unit> extraUnits = const [],
}) {
  final treasury = sellerTreasury < 0
      ? cheapestRegimentBuildTreasuryCost()
      : sellerTreasury;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|s$i',
        regionId: kRegionOldWorld,
        ownerId: supplierFeedstockId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|p$i',
        regionId: kRegionOldWorld,
        ownerId: sellerFeedstockId,
      ),
  ];
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces, units: extraUnits),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
      tileState: tileState ?? TileMapState(),
    ),
    players: [
      Player(
        id: supplierFeedstockId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        // Supplier holds no timber/iron surplus — it must extract more.
        stockpile: const Stockpile(),
      ),
      Player(
        id: sellerFeedstockId,
        displayName: 'Seller',
        isHuman: false,
        treasury: treasury,
        stockpile: sellerStockpile,
      ),
    ],
  );
}

PlayerView supplierBuilderView(Game game) {
  return PlayerView(
    playerId: supplierFeedstockId,
    player: game.players.firstWhere((p) => p.id == supplierFeedstockId),
    ownUnitsById: {
      'b1': Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: supplierFeedstockId,
        locationProvinceId: 'oldWorld|s0',
      ),
    },
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

extension SupplierFeedstockProspectedGame on Game {
  /// Returns a copy of this game with [supplierFeedstockId]'s prospected-tile
  /// set replaced by [tiles] (test helper for mineral feedstock prospecting).
  Game copyWithSupplierProspected(Set<String> tiles) {
    return Game(
      id: id,
      worldState: WorldState(
        turnState: worldState.turnState,
        oldWorld: worldState.oldWorld,
        newWorld: worldState.newWorld,
        resourceByTileKey: worldState.resourceByTileKey,
        tileState: worldState.tileState,
        playerProspectedTiles: {supplierFeedstockId: tiles},
      ),
      players: players,
    );
  }
}
