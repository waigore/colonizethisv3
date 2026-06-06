/// Regiment build-input production priority (Refs #2847 H8 production companion).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _topology = MapTopology(nodes: [], edges: []);

Game _regimentRebuildProductionGame({
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
/// `timber` + `iron` so the `castIron_from_timber_iron_coal` recipe is feasible,
/// and zero `castIron`. Refs #2847 § H8-extraction castIron residual.
Game _castIronImprovementInputGame({
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
/// active, like [_castIronImprovementInputGame]) with an affluent supplier
/// (`gp_supplier`) holding `timber` + `iron` feedstock and ample labour, above
/// the conquest quota so it is **not** a lock-recovery seller. Refs #2847
/// H8-supply castIron source. When [sellerGateActive] is false the seller holds
/// `castIron`, so no locked seller needs the improvement input and the supplier
/// over-production trigger is off (negative control).
Game _supplierCastIronSourceGame({
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
/// multi-input `castIron_from_timber_iron_coal` recipe is assembling
/// (Refs #2847 § H8-extraction feedstock co-availability). When [gateActive] is
/// false the unimproved feedstock tile is removed, so the seller is no longer a
/// reserve-target GP (negative control — no feedstock reservation).
Game _castIronFeedstockCoavailabilityGame({
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
/// `castIron_from_timber_iron_coal` recipe is materially feasible. This is the
/// seed-42 gp5 profile after its fabric feedstock tile has been improved: the
/// prior `selfLockRecoverySellerNeededProducibleImprovementInputs` set is empty
/// here, so only the new stageable path can assign the domestic castIron run.
/// Refs #2847 § H8 production allocation (S7-D castIron, PR #3289). When
/// [ownsFeedstockTile] is false the timber tile is removed (the seller no longer
/// owns castIron feedstock to extract), so the staging gate self-clears
/// (negative control). [owProvinces] >= the conquest quota lifts the seller out
/// of the lock-recovery band (negative control).
Game _castIronStagingNoFabricGateGame({
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

PhasePlanOutcome _expandForceRegimentBuildPlan({
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
/// (2 peasants < castIron run labour). Refs #2847 castIron-labour peasant-recruit
/// fabric bootstrap.
Game _castIronLabourPeasantRecruitFabricStagingGame({required int fabricHeld}) {
  const ow = 'oldWorld';
  const tileTimber = 'oldWorld|seller_0|2|0';
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
      resourceByTileKey: const {tileTimber: 'timber'},
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|seller_0': [tileTimber],
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
            .applyDelta(CommodityCatalog.timber.id, 2)
            .applyDelta(CommodityCatalog.iron.id, 2)
            .applyDelta(CommodityCatalog.wool.id, 10)
            .applyDelta(CommodityCatalog.fabric.id, fabricHeld),
        workerPool: const WorkerPool(peasants: 2),
      ),
    ],
  );
}

Set<String> _assignedRecipeIds(EconomyPlan plan) =>
    plan.productionAssignments.map((a) => a.recipeId).toSet();

void main() {
  group('regiment build-input production priority (Refs #2847 H8)', () {
    const config = AIConfig(
      leaderId: 'victoria',
      personalityId: 'victoria',
      hiddenAgendaId: 'peacemaker',
    );
    final seeds = AISeedBundle.fromTurnSeed(42);
    final threshold = cheapestRegimentBuildTreasuryCost();

    test(
      'forceCheapestRegimentBuild prioritizes a fabric recipe when fabric is '
      'missing and treasury has recovered',
      () {
        final game = _regimentRebuildProductionGame(treasury: threshold);
        final view = buildPlayerView(game, _topology, 'gp1');

        final withBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        final fabricRecipeIds = {
          ProductionRecipesCatalog.fabricFromWool.id,
          ProductionRecipesCatalog.fabricFromCotton.id,
        };
        expect(
          _assignedRecipeIds(withBoost).intersection(fabricRecipeIds),
          isNotEmpty,
          reason:
              'H8 production boost should assign labour to a fabric recipe '
              'when wool/cotton inputs are available and fabric is missing',
        );
      },
    );

    test(
      'forceCheapestRegimentBuild stages fabric even when treasury is below '
      'the regiment threshold (Refs #2847 H8 production allocation)',
      () {
        // Treasury-independent staging: the build input is produced ahead of
        // treasury recovery so it is on hand the moment treasury crosses the
        // cost. Production spends no treasury, so the broke turn is exactly
        // when the seller must build up the input.
        final game = _regimentRebuildProductionGame(treasury: threshold - 1);
        final view = buildPlayerView(game, _topology, 'gp1');

        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        expect(
          _assignedRecipeIds(plan).intersection({
            ProductionRecipesCatalog.fabricFromWool.id,
            ProductionRecipesCatalog.fabricFromCotton.id,
          }),
          isNotEmpty,
          reason:
              'A zero-regiment GP on the EXPAND rebuild directive must stage the '
              'cheapest regiment build input even while broke; production spends '
              'no treasury, so the input is banked for when treasury recovers.',
        );
      },
    );

    test(
      'no H8 production boost once the GP already holds a regiment '
      '(negative control — +6 baseline GPs unaffected)',
      () {
        // A regiment-holding GP is past the rebuild trap, so the staging boost
        // must not fire. Compare fabric labour against the same seed with the
        // boost-eligible (zero-regiment) game to prove the regiment is the only
        // differing input that suppresses the boost.
        final withRegiment = _regimentRebuildProductionGame(
          treasury: threshold,
          hasRegiment: true,
        );
        final withRegimentPlan = runEconomyPlanner(
          game: withRegiment,
          view: buildPlayerView(withRegiment, _topology, 'gp1'),
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        final zeroRegiment = _regimentRebuildProductionGame(treasury: threshold);
        final zeroRegimentPlan = runEconomyPlanner(
          game: zeroRegiment,
          view: buildPlayerView(zeroRegiment, _topology, 'gp1'),
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        int fabricLabour(EconomyPlan plan) {
          final fabricIds = {
            ProductionRecipesCatalog.fabricFromWool.id,
            ProductionRecipesCatalog.fabricFromCotton.id,
          };
          return plan.productionAssignments
              .where((a) => fabricIds.contains(a.recipeId))
              .fold<int>(0, (sum, a) => sum + a.assignedLabour);
        }

        expect(
          fabricLabour(withRegimentPlan),
          lessThanOrEqualTo(fabricLabour(zeroRegimentPlan)),
          reason:
              'Holding a regiment must not increase fabric labour; the '
              'zero-regiment path is the only one that receives the H8 staging '
              'boost.',
        );
      },
    );

    test(
      'same seed without forceCheapestRegimentBuild may omit fabric when '
      'competing recipes score higher',
      () {
        final game = _regimentRebuildProductionGame(treasury: threshold);
        final view = buildPlayerView(game, _topology, 'gp1');

        final withoutBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: false,
          ),
        );

        // Pin only that the H8-boosted path is strictly stronger for fabric:
        // turning the directive on must not reduce fabric labour vs off when
        // fabric was already assigned.
        final withBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );

        int fabricLabour(EconomyPlan plan) {
          final fabricIds = {
            ProductionRecipesCatalog.fabricFromWool.id,
            ProductionRecipesCatalog.fabricFromCotton.id,
          };
          return plan.productionAssignments
              .where((a) => fabricIds.contains(a.recipeId))
              .fold<int>(0, (sum, a) => sum + a.assignedLabour);
        }

        expect(
          fabricLabour(withBoost),
          greaterThanOrEqualTo(fabricLabour(withoutBoost)),
        );
      },
    );

    test(
      'domestic improvement-input boost assigns a castIron recipe when the '
      'improvement-input gate is active and feedstock is on hand',
      () {
        final game = _castIronImprovementInputGame(treasury: threshold);
        final view = buildPlayerView(game, _topology, 'gp_seller');

        // No forceCheapestRegimentBuild directive: the boost is driven solely by
        // the active improvement-input gate.
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );

        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.castIronFromTimberIronCoal.id),
          reason:
              'When the seller must produce castIron domestically (no market '
              'supply) and holds the timber + iron feedstock, the production '
              'boost must assign the castIron recipe.',
        );
      },
    );

    test(
      'no domestic castIron boost when the improvement-input gate is inactive '
      '(negative control — healthy GPs unaffected)',
      () {
        // gateActive: false removes the owned unimproved feedstock tile, so
        // `regimentBuildInputFeedstockImprovementInputCost` returns empty and the
        // castIron output gets no H8 boost (+6 baseline GPs are unaffected).
        final game = _castIronImprovementInputGame(
          treasury: threshold,
          gateActive: false,
        );
        final view = buildPlayerView(game, _topology, 'gp_seller');

        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );

        // With no boost, castIron is not assigned solely because of H8 (it may
        // still appear from ordinary scoring, so assert the boost did not force
        // it by comparing against the same seed where the gate is the only
        // differing input).
        final gated = runEconomyPlanner(
          game: _castIronImprovementInputGame(treasury: threshold),
          view: buildPlayerView(
            _castIronImprovementInputGame(treasury: threshold),
            _topology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        final castIronId =
            ProductionRecipesCatalog.castIronFromTimberIronCoal.id;
        int castIronLabour(EconomyPlan plan) => plan.productionAssignments
            .where((a) => a.recipeId == castIronId)
            .fold<int>(0, (sum, a) => sum + a.assignedLabour);
        expect(
          castIronLabour(plan),
          lessThanOrEqualTo(castIronLabour(gated)),
          reason:
              'Activating the improvement-input gate must not reduce castIron '
              'labour; the gate-inactive path receives no domestic-production '
              'boost.',
        );
      },
    );

    int castIronLabour(EconomyPlan plan) => plan.productionAssignments
        .where(
          (a) =>
              a.recipeId == ProductionRecipesCatalog.castIronFromTimberIronCoal.id,
        )
        .fold<int>(0, (sum, a) => sum + a.assignedLabour);

    test(
      'affluent supplier over-produces castIron when a peer lock-recovery '
      'seller needs the castIron improvement input (Refs #2847 H8-supply '
      'castIron source)',
      () {
        final game = _supplierCastIronSourceGame(treasury: threshold);
        final supplierView = buildPlayerView(game, _topology, 'gp_supplier');
        final plan = runEconomyPlanner(
          game: game,
          view: supplierView,
          config: config,
          seeds: seeds,
        );
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.castIronFromTimberIronCoal.id),
          reason:
              'A supplier that is not a locked seller must over-produce castIron '
              'for release while a peer lock-recovery seller still needs the '
              'castIron improvement input.',
        );
      },
    );

    test(
      'supplier castIron over-production is off when no peer needs the castIron '
      'improvement input (negative control — +6 baseline GPs unaffected)',
      () {
        final active = runEconomyPlanner(
          game: _supplierCastIronSourceGame(treasury: threshold),
          view: buildPlayerView(
            _supplierCastIronSourceGame(treasury: threshold),
            _topology,
            'gp_supplier',
          ),
          config: config,
          seeds: seeds,
        );
        final inactive = runEconomyPlanner(
          game: _supplierCastIronSourceGame(
            treasury: threshold,
            sellerGateActive: false,
          ),
          view: buildPlayerView(
            _supplierCastIronSourceGame(
              treasury: threshold,
              sellerGateActive: false,
            ),
            _topology,
            'gp_supplier',
          ),
          config: config,
          seeds: seeds,
        );
        expect(
          castIronLabour(inactive),
          lessThanOrEqualTo(castIronLabour(active)),
          reason:
              'Removing the peer locked seller must not increase the supplier '
              'castIron labour; the supplier-release boost only fires while a '
              'peer needs the improvement input.',
        );
      },
    );

    int lumberLabour(EconomyPlan plan) => plan.productionAssignments
        .where((a) => a.recipeId == ProductionRecipesCatalog.lumberFromTimber.id)
        .fold<int>(0, (sum, a) => sum + a.assignedLabour);

    test(
      'affluent supplier over-produces lumber when a peer lock-recovery seller '
      'is short the binding level-0 lumber improvement input (Refs #2847 '
      'H8-supply S7-D lumber re-localization)',
      () {
        // The locked seller holds zero lumber (default supplier-source game),
        // so lumber — the binding level-0 build_improvement input (castIron is
        // waived at level 0) — joins the supplier's peer-needed producible set.
        // The supplier holds no `iron` (mirrors the seed-42 condition where the
        // supplier's mineral feedstock is never prospected), so the multi-input
        // `castIron` recipe is infeasible and lumber is the released output.
        final game = _supplierCastIronSourceGame(
          treasury: threshold,
          supplierIronHeld: 0,
        );
        final supplierView = buildPlayerView(game, _topology, 'gp_supplier');
        final plan = runEconomyPlanner(
          game: game,
          view: supplierView,
          config: config,
          seeds: seeds,
        );
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.lumberFromTimber.id),
          reason:
              'A supplier that is not a locked seller must over-produce lumber '
              'for release while a peer lock-recovery seller is short the '
              'binding level-0 lumber improvement input.',
        );
      },
    );

    test(
      'supplier lumber over-production is off when no peer is a lock-recovery '
      'seller (negative control — +6 baseline GPs unaffected)',
      () {
        // Active: a below-quota seller short lumber exists, so the supplier
        // over-produces lumber. Inactive: the would-be seller is at quota (12
        // OW provinces), so no peer needs the input and the release boost is
        // off. The supplier-release boost must never raise lumber labour in the
        // inactive case above the active case.
        final active = runEconomyPlanner(
          game: _supplierCastIronSourceGame(
            treasury: threshold,
            supplierIronHeld: 0,
          ),
          view: buildPlayerView(
            _supplierCastIronSourceGame(treasury: threshold, supplierIronHeld: 0),
            _topology,
            'gp_supplier',
          ),
          config: config,
          seeds: seeds,
        );
        final inactive = runEconomyPlanner(
          game: _supplierCastIronSourceGame(
            treasury: threshold,
            sellerOwProvinces: 12,
            supplierIronHeld: 0,
          ),
          view: buildPlayerView(
            _supplierCastIronSourceGame(
              treasury: threshold,
              sellerOwProvinces: 12,
              supplierIronHeld: 0,
            ),
            _topology,
            'gp_supplier',
          ),
          config: config,
          seeds: seeds,
        );
        expect(
          lumberLabour(inactive),
          lessThanOrEqualTo(lumberLabour(active)),
          reason:
              'Removing the peer locked seller must not increase the supplier '
              'lumber labour; the supplier-release boost only fires while a peer '
              'needs the improvement input.',
        );
      },
    );

    test(
      'reserve-target GP withholds timber from the competing lumber recipe '
      'while assembling a castIron run (Refs #2847 H8-extraction feedstock '
      'co-availability)',
      () {
        // 2 timber + 0 iron: enough timber for one lumber_from_timber run but
        // not yet a castIron run. The reserve must withhold the 2 timber so the
        // single-input lumber recipe cannot drain it.
        final game = _castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 0,
        );
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );
        expect(
          lumberLabour(plan),
          0,
          reason:
              'With the castIron reserve active, the 2 held timber are withheld '
              'from lumber_from_timber so they carry over toward a castIron run.',
        );
      },
    );

    test(
      'non-reserve GP consumes the same timber via the lumber recipe '
      '(negative control — no feedstock reservation when castIron is not '
      'targeted)',
      () {
        // gateActive: false removes the feedstock tile, so the GP is not a
        // castIron reserve target; the feasible lumber recipe consumes timber.
        final game = _castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 0,
          gateActive: false,
        );
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );
        expect(
          lumberLabour(plan),
          greaterThan(0),
          reason:
              'Without a castIron reserve target, the feasible lumber_from_timber '
              'recipe consumes the 2 held timber (the reservation is the only '
              'differing behaviour).',
        );
      },
    );

    test(
      'reserve-target GP assigns the castIron recipe once a full run of '
      'feedstock co-accumulates (Refs #2847 H8-extraction feedstock '
      'co-availability)',
      () {
        // 2 timber + 2 iron: one full castIron run is now co-available, so the
        // boosted multi-input recipe runs.
        final game = _castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 2,
        );
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.castIronFromTimberIronCoal.id),
          reason:
              'With timber + iron co-available the reserved feedstock lets the '
              'boosted castIron recipe run.',
        );
      },
    );

    test(
      'locked seller produces lumber domestically from surplus timber when '
      'iron is unavailable (Refs #2847 H8-extraction S7-D lumber '
      're-localization)',
      () {
        // 8 timber + 0 iron: the multi-input castIron recipe is infeasible (no
        // iron), and beyond the {timber: 2, iron: 2} castIron reserve there is
        // surplus timber (6) for lumber_from_timber. The seller is short the
        // binding level-0 lumber input (waived castIron), so lumber joins the
        // seller-side domestic production set and is produced from owned timber
        // instead of depending on the thin lumber market.
        final game = _castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 8,
          iron: 0,
        );
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.lumberFromTimber.id),
          reason:
              'A locked seller short the binding level-0 lumber input must '
              'produce lumber domestically from its surplus timber.',
        );
      },
    );

    test(
      'single-input lumber is excluded from the castIron feedstock reserve so '
      'co-availability is preserved even when the seller also needs lumber '
      '(Refs #2847 H8-extraction S7-D lumber re-localization)',
      () {
        // 2 timber + 2 iron: exactly one castIron run is co-available. Even
        // though the seller is now also short lumber (so lumber is in the
        // domestic production set), lumber is single-input and must be excluded
        // from the feedstock reserve — otherwise it would drain the 2 timber the
        // castIron run is assembling. The reserve withholds the timber from
        // lumber_from_timber, and the castIron run proceeds.
        final game = _castIronFeedstockCoavailabilityGame(
          treasury: threshold,
          timber: 2,
          iron: 2,
        );
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );
        expect(
          lumberLabour(plan),
          0,
          reason:
              'Single-input lumber must not be a reserve target; the 2 timber '
              'stay withheld for the multi-input castIron run.',
        );
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.castIronFromTimberIronCoal.id),
          reason:
              'With timber + iron co-available the reserved feedstock lets the '
              'boosted castIron recipe run despite the concurrent lumber need.',
        );
      },
    );

    test(
      'reserve-target allocation is deterministic across identical runs',
      () {
        Set<String> run() {
          final game = _castIronFeedstockCoavailabilityGame(
            treasury: threshold,
            timber: 2,
            iron: 0,
          );
          return _assignedRecipeIds(
            runEconomyPlanner(
              game: game,
              view: buildPlayerView(game, _topology, 'gp_seller'),
              config: config,
              seeds: seeds,
            ),
          );
        }

        expect(run(), equals(run()));
      },
    );

    test(
      'lock-recovery seller stages castIron when it co-holds timber + iron and '
      'owns a feedstock tile even after the fabric improvement gate goes '
      'inactive (Refs #2847 H8 production allocation — S7-D castIron, PR #3289)',
      () {
        final game = _castIronStagingNoFabricGateGame(treasury: threshold);
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
        );
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.castIronFromTimberIronCoal.id),
          reason:
              'A recovered lock-recovery seller that no longer owns an '
              'unimproved fabric tile but still co-holds timber + iron and owns '
              'a feedstock tile must stage the feasible castIron run.',
        );
      },
    );

    test(
      'castIron staging is off once the seller owns no feedstock tile '
      '(negative control — staging requires an owned feedstock tile)',
      () {
        final active = runEconomyPlanner(
          game: _castIronStagingNoFabricGateGame(treasury: threshold),
          view: buildPlayerView(
            _castIronStagingNoFabricGateGame(treasury: threshold),
            _topology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        final inactive = runEconomyPlanner(
          game: _castIronStagingNoFabricGateGame(
            treasury: threshold,
            ownsFeedstockTile: false,
          ),
          view: buildPlayerView(
            _castIronStagingNoFabricGateGame(
              treasury: threshold,
              ownsFeedstockTile: false,
            ),
            _topology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        expect(
          castIronLabour(inactive),
          lessThanOrEqualTo(castIronLabour(active)),
          reason:
              'Removing the owned feedstock tile must not increase castIron '
              'labour; the stageable boost only fires while the seller owns a '
              'castIron feedstock tile.',
        );
      },
    );

    test(
      'castIron staging is off for an above-quota GP (negative control — '
      '+6 baseline GPs unaffected)',
      () {
        final belowQuota = runEconomyPlanner(
          game: _castIronStagingNoFabricGateGame(treasury: threshold),
          view: buildPlayerView(
            _castIronStagingNoFabricGateGame(treasury: threshold),
            _topology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        final aboveQuota = runEconomyPlanner(
          game: _castIronStagingNoFabricGateGame(
            treasury: threshold,
            owProvinces: 12,
          ),
          view: buildPlayerView(
            _castIronStagingNoFabricGateGame(
              treasury: threshold,
              owProvinces: 12,
            ),
            _topology,
            'gp_seller',
          ),
          config: config,
          seeds: seeds,
        );
        expect(
          castIronLabour(aboveQuota),
          lessThanOrEqualTo(castIronLabour(belowQuota)),
          reason:
              'Lifting the GP above the conquest quota must not increase '
              'castIron labour; only below-quota lock-recovery sellers stage it.',
        );
      },
    );

    test(
      'castIron-labour peasant-recruit fabric boost stages fabric when one unit '
      'is held but recruit cost is two (Refs #2847)',
      () {
        final game = _castIronLabourPeasantRecruitFabricStagingGame(
          fabricHeld: 1,
        );
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final plan = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
            boostCastIronLabourPeasantRecruitment: true,
          ),
        );
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.fabricFromWool.id),
          reason:
              'One fabric is enough for regiment build but not the 2-fabric '
              'peasant recruit row; the castIron-labour fabric boost must still '
              'stage domestic fabric production.',
        );
      },
    );

    test(
      'castIron-labour peasant-recruit fabric boost is off once fabric meets '
      'recruit cost (negative control)',
      () {
        final game = _castIronLabourPeasantRecruitFabricStagingGame(fabricHeld: 2);
        final view = buildPlayerView(game, _topology, 'gp_seller');
        final withBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
            boostCastIronLabourPeasantRecruitment: true,
          ),
        );
        final withoutBoost = runEconomyPlanner(
          game: game,
          view: view,
          config: config,
          seeds: seeds,
          phasePlan: _expandForceRegimentBuildPlan(
            forceCheapestRegimentBuild: true,
          ),
        );
        expect(
          _assignedRecipeIds(withBoost),
          equals(_assignedRecipeIds(withoutBoost)),
          reason:
              'When fabric already meets the recruit cost the peasant-recruit '
              'fabric boost must not change production assignments.',
        );
      },
    );
  });
}
