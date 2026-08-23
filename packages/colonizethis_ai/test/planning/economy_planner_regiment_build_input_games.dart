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
      boostCastIronLabourPeasantRecruitment:
          boostCastIronLabourPeasantRecruitment,
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
