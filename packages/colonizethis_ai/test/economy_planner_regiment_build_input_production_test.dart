/// Regiment build-input production priority (Refs #2847 H8 production companion).
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _topology = MapTopology(nodes: [], edges: []);

Game _regimentRebuildProductionGame({required int treasury}) {
  return Game(
    id: 'g-h8-production',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
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
      newWorld: RegionData(),
      armies: [],
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
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-h8-castiron-supplier-source',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < 3; i++)
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
            .applyDelta(CommodityCatalog.iron.id, 40)
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

PhasePlanOutcome _expandForceRegimentBuildPlan({
  required bool forceCheapestRegimentBuild,
}) {
  return PhasePlanOutcome(
    phase: ObserverGoalPhase.expand,
    expandEconomyPlan: ExpandEconomyPlan(
      forceCheapestRegimentBuild: forceCheapestRegimentBuild,
      boostTreasuryRecoveryCargo: false,
    ),
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
      'forceCheapestRegimentBuild does not apply when treasury is below the '
      'regiment threshold',
      () {
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
          isEmpty,
          reason:
              'without recovered treasury the H8 boost must not fire even when '
              'the EXPAND directive is set',
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
  });
}
