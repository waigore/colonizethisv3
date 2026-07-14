// Shared scaffolding for economy planner regiment build-input production
// contract suites (Refs #3972 / #2847 H8).
//
// Game builders and phase-plan helpers are shared so the production pin file
// stays under the non-comment line gate without dropping coverage.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const kRegimentBuildInputEmptyTopology = MapTopology(nodes: [], edges: []);

Game regimentRebuildProductionGame({
  required int treasury,
  bool hasRegiment = false,
}) {
  return Game(
    id: 'g-h8-production',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: 'oldWorld|p0',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [
        if (hasRegiment)
          const Army(
            id: 'army-gp1-field',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p0',
            regimentUnitIds: ['reg-1'],
          ),
      ],
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: 'oldWorld|p0',
        treasury: treasury,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.wool.id, 10)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

/// A below-quota zero-NW lock-recovery seller whose improvement-input gate
/// (`regimentBuildInputFeedstockImprovementInputCost`) is active: recovered
/// treasury, zero regiments, 3 Old World provinces, zero New World, missing
/// `fabric`, and an owned **unimproved** `wool` resource tile. Holds
/// `timber` + `iron` so the `castIron_from_iron` recipe is feasible,
/// and zero `castIron`. Refs #2847 § H8-extraction castIron residual.
Game castIronImprovementInputGame({
  required int treasury,
  bool gateActive = true,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-h8-castiron-production',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 3; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      // Unimproved wool resource tile in the seller's capital province (only
      // present when the gate should be active).
      resourceByTileKey: gateActive
          ? const {'oldWorld|seller_0|1|0': 'wool'}
          : const {},
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        treasury: treasury,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

/// A two-GP game pairing a locked seller (castIron improvement-input gate
/// active, like [castIronImprovementInputGame]) with an affluent supplier
/// (`gp_supplier`) holding `timber` + `iron` feedstock and ample labour, above
/// the conquest quota so it is **not** a lock-recovery seller. Refs #2847
/// H8-supply castIron source. When [sellerGateActive] is false the seller holds
/// `castIron`, so no locked seller needs the improvement input and the supplier
/// over-production trigger is off (negative control).
Game supplierCastIronSourceGame({
  required int treasury,
  bool sellerGateActive = true,
  int sellerOwProvinces = 3,
  int supplierIronHeld = 40,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-h8-castiron-supplier-source',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < sellerOwProvinces; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
          for (var i = 0; i < 12; i++)
            Province(
              id: '$ow|supplier_$i',
              regionId: ow,
              ownerId: 'gp_supplier',
            ),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: const {'oldWorld|seller_0|1|0': 'wool'},
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        treasury: treasury,
        stockpile: sellerGateActive
            ? const Stockpile().applyDelta(CommodityCatalog.grain.id, 30)
            : const Stockpile()
                .applyDelta(CommodityCatalog.grain.id, 30)
                .applyDelta(CommodityCatalog.castIron.id, 1),
        workerPool: const WorkerPool(peasants: 12),
      ),
      Player(
        id: 'gp_supplier',
        displayName: 'Supplier',
        isHuman: false,
        capitalProvinceId: '$ow|supplier_0',
        treasury: treasury,
        // Ample feedstock + labour and no competing output shortage (every
        // feasible output held at the shortage threshold, 8) so the supplier
        // has genuine spare capacity: the small leftover-capacity castIron
        // release boost is the differentiator, not shortage scoring.
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 80)
            .applyDelta(CommodityCatalog.timber.id, 40)
            .applyDelta(CommodityCatalog.iron.id, supplierIronHeld)
            .applyDelta(CommodityCatalog.castIron.id, 8)
            .applyDelta(CommodityCatalog.lumber.id, 8)
            .applyDelta(CommodityCatalog.paper.id, 8),
        workerPool: const WorkerPool(peasants: 40),
      ),
    ],
  );
}

/// A below-quota zero-NW lock-recovery seller whose castIron improvement-input
/// gate is active, with **configurable** `timber` / `iron` feedstock so a test
/// can pin the partial-feedstock state where the single-input
/// `lumber_from_timber` recipe would otherwise drain the `timber` the
/// multi-input `castIron_from_iron` recipe is assembling
/// (Refs #2847 § H8-extraction feedstock co-availability). When [gateActive] is
/// false the unimproved feedstock tile is removed, so the seller is no longer a
/// reserve-target GP (negative control — no feedstock reservation).
Game castIronFeedstockCoavailabilityGame({
  required int treasury,
  required int timber,
  required int iron,
  bool gateActive = true,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-h8-castiron-coavailability',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 3; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: gateActive
          ? const {'oldWorld|seller_0|1|0': 'wool'}
          : const {},
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        treasury: treasury,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.timber.id, timber)
            .applyDelta(CommodityCatalog.iron.id, iron),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

/// A below-quota zero-NW lock-recovery seller whose **fabric** improvement-cost
/// gate is inactive — it owns a `castIron`-feedstock (`timber`) tile but **no**
/// unimproved `wool` / `cotton` tile — yet co-holds `timber` + `iron` so the
/// `castIron_from_iron` recipe is materially feasible. This is the
/// seed-42 gp5 profile after its fabric feedstock tile has been improved: the
/// prior `selfLockRecoverySellerNeededProducibleImprovementInputs` set is empty
/// here, so only the new stageable path can assign the domestic castIron run.
/// Refs #2847 § H8 production allocation (S7-D castIron, PR #3289). When
/// [ownsFeedstockTile] is false the timber tile is removed (the seller no longer
/// owns castIron feedstock to extract), so the staging gate self-clears
/// (negative control). [owProvinces] >= the conquest quota lifts the seller out
/// of the lock-recovery band (negative control).
Game castIronStagingNoFabricGateGame({
  required int treasury,
  bool ownsFeedstockTile = true,
  int owProvinces = 3,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-h8-castiron-staging',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < owProvinces; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      // Owns a `timber` feedstock tile but NO `wool` / `cotton` tile, so the
      // fabric improvement-cost gate is inactive and the prior self-need helper
      // is empty — isolating the new stageable path.
      resourceByTileKey: ownsFeedstockTile
          ? const {'oldWorld|seller_0|2|0': 'timber'}
          : const {},
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        treasury: treasury,
        // Holds timber + iron (castIron feedstock) but zero castIron.
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

PhasePlanOutcome expandForceRegimentBuildPlan({
  required bool forceCheapestRegimentBuild,
  bool boostCastIronLabourPeasantRecruitment = false,
}) {
  return PhasePlanOutcome(
    phase: ObserverGoalPhase.expand,
    expandEconomyPlan: ExpandEconomyPlan(
      forceCheapestRegimentBuild: forceCheapestRegimentBuild,
      boostTreasuryRecoveryCargo: false,
      boostCastIronLabourPeasantRecruitment: boostCastIronLabourPeasantRecruitment,
    ),
  );
}

/// Lock-recovery seller holding one `fabric` (enough for regiment build but
/// short the 2-`fabric` peasant recruit row) with wool feedstock for a
/// domestic fabric run, castIron material-feasible yet labour-population-bound
/// (1 peasant < castIron run labour of 2). Refs #2847 castIron-labour peasant-recruit
/// fabric bootstrap.
Game castIronLabourPeasantRecruitFabricStagingGame({required int fabricHeld}) {
  const ow = 'oldWorld';
  const tileIron = 'oldWorld|seller_0|2|0';
  return Game(
    id: 'g-h8-peasant-recruit-fabric',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 3; i++)
            Province(id: '$ow|seller_$i', regionId: ow, ownerId: 'gp_seller'),
        ],
      ),
      newWorld: const RegionData(provinces: []),
      resourceByTileKey: const {tileIron: 'iron'},
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|seller_0': [tileIron],
        },
      },
    ),
    players: [
      Player(
        id: 'gp_seller',
        displayName: 'Seller',
        isHuman: false,
        capitalProvinceId: '$ow|seller_0',
        treasury: cheapestRegimentBuildTreasuryCost(),
        stockpile: Stockpile.empty
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 4)
            .applyDelta(CommodityCatalog.wool.id, 10)
            .applyDelta(CommodityCatalog.fabric.id, fabricHeld),
        workerPool: const WorkerPool(peasants: 1),
      ),
    ],
  );
}

Set<String> assignedRecipeIds(EconomyPlan plan) =>
    plan.productionAssignments.map((a) => a.recipeId).toSet();

