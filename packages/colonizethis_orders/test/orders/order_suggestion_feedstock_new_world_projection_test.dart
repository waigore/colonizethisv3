import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show feedstockExtractionResourceIdsForPlayer;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Refs #3393 Phase 6b (slice 5) — `_newWorldProvinceCountOwnedBy` reads
// `ProvinceOwnerCache.countOwnedByInRegion(playerId, kRegionNewWorld)`.
const _supplierId = 'gp1';
const _sellerId = 'gp2';
const _timberTile = 'oldWorld|gp1-s0|1|0';
const _grainTile = 'oldWorld|gp1-s0|0|0';
const _sellerWoolTile = 'oldWorld|gp2-p0|0|0';

Game _feedstockGateGame({int sellerNw = 0}) {
  const supplierOw = kObserverConquestMinOwProvincesPerGp;
  const sellerOw = 5;
  final provinces = <Province>[
    for (var i = 0; i < supplierOw; i++)
      Province(
        id: 'oldWorld|gp1-s$i',
        regionId: kRegionOldWorld,
        ownerId: _supplierId,
      ),
    for (var i = 0; i < sellerOw; i++)
      Province(
        id: 'oldWorld|gp2-p$i',
        regionId: kRegionOldWorld,
        ownerId: _sellerId,
      ),
  ];
  final newWorldProvinces = <Province>[
    for (var i = 0; i < sellerNw; i++)
      Province(
        id: 'newWorld|gp2-n$i',
        regionId: kRegionNewWorld,
        ownerId: _sellerId,
      ),
  ];
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileKeysByRegionAndProvince: const {
        kRegionOldWorld: {
          'oldWorld|gp1-s0': [_grainTile, _timberTile],
          'oldWorld|gp2-p0': [_sellerWoolTile],
        },
      },
      resourceByTileKey: const {
        _grainTile: 'grain',
        _timberTile: 'timber',
        _sellerWoolTile: 'wool',
      },
      tileState: const TileMapState(
        improvementByTile: {_grainTile: 0, _timberTile: 0, _sellerWoolTile: 0},
      ),
    ),
    players: [
      Player(
        id: _supplierId,
        displayName: 'Supplier',
        isHuman: false,
        treasury: 100000,
        stockpile: const Stockpile(quantities: {'lumber': 10}),
      ),
      Player(
        id: _sellerId,
        displayName: 'Seller',
        isHuman: false,
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: const Stockpile(quantities: {'lumber': 1}),
      ),
    ],
  );
}

void main() {
  test(
    'seller owning a New World province deactivates the feedstock gate '
    '(projection-backed new-world count, Refs #3393)',
    () {
      expect(
        feedstockExtractionResourceIdsForPlayer(
          _feedstockGateGame(),
          _supplierId,
        ),
        containsAll(<String>['timber', 'iron']),
      );

      final game = _feedstockGateGame(sellerNw: 1);
      expect(
        feedstockExtractionResourceIdsForPlayer(game, _supplierId),
        isEmpty,
        reason:
            'a below-quota seller owning a New World province is no longer a '
            'zero-NW lock-recovery seller, so the peer-supplier gate must empty',
      );
    },
  );
}
