/// Slice C — cotton weaving recipe gate in the AI economy planner (Refs #3470).
///
/// SPEC/game/production-recipes.md § Technology-gated recipes:
/// `fabric_from_cotton` is available only to a player whose `techUnlocked` set
/// maps `cotton_weaving` to `true`. The AI economy planner must never score,
/// assign labour to, or suggest a tech-locked recipe.
library;

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _topology = MapTopology(nodes: [], edges: []);

/// A single-GP game whose only fabric feedstock is [cotton] cotton (no wool),
/// so the only feasible fabric recipe is `fabric_from_cotton`. [techUnlocked]
/// controls whether the GP has researched `cotton_weaving`.
Game _cottonOnlyGame({
  required int cotton,
  Map<String, bool>? techUnlocked,
}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-cotton-gate',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
      oldWorld: const RegionData(
        provinces: [
          Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p0',
        treasury: 100,
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 30)
            .applyDelta(CommodityCatalog.cotton.id, cotton),
        workerPool: const WorkerPool(peasants: 12),
        techUnlocked: techUnlocked,
      ),
    ],
  );
}

Set<String> _assignedRecipeIds(EconomyPlan plan) =>
    plan.productionAssignments.map((a) => a.recipeId).toSet();

void main() {
  const config = AIConfig(
    leaderId: 'victoria',
    personalityId: 'victoria',
    hiddenAgendaId: 'merchant',
  );
  final seeds = AISeedBundle.fromTurnSeed(42);

  EconomyPlan planFor(Map<String, bool>? techUnlocked) {
    final game = _cottonOnlyGame(cotton: 100, techUnlocked: techUnlocked);
    return runEconomyPlanner(
      game: game,
      view: buildPlayerView(game, _topology, 'gp1'),
      config: config,
      seeds: seeds,
    );
  }

  group('cotton weaving recipe gate (Refs #3470 Slice C)', () {
    test(
      'fabric_from_cotton is NOT assigned for a GP without cotton_weaving '
      '(null techUnlocked)',
      () {
        final plan = planFor(null);
        expect(
          _assignedRecipeIds(plan),
          isNot(contains(ProductionRecipesCatalog.fabricFromCotton.id)),
          reason: 'A GP that has not researched cotton_weaving must never be '
              'assigned the tech-locked fabric_from_cotton recipe.',
        );
      },
    );

    test(
      'fabric_from_cotton is NOT assigned when cotton_weaving is explicitly '
      'false',
      () {
        final plan = planFor(const {kTechIdCottonWeaving: false});
        expect(
          _assignedRecipeIds(plan),
          isNot(contains(ProductionRecipesCatalog.fabricFromCotton.id)),
        );
      },
    );

    test(
      'no fabric is produced at all when cotton is the only feedstock and '
      'cotton_weaving is locked',
      () {
        // With cotton the only fabric input and the recipe locked, the planner
        // has no feasible fabric path, so no fabric-producing recipe appears.
        final plan = planFor(null);
        final fabricRecipeIds = ProductionRecipesCatalog.all
            .where((r) => r.outputCommodityId == CommodityCatalog.fabric.id)
            .map((r) => r.id)
            .toSet();
        expect(
          _assignedRecipeIds(plan).intersection(fabricRecipeIds),
          isEmpty,
          reason: 'fabric_from_wool needs wool (none held) and '
              'fabric_from_cotton is locked, so no fabric recipe is feasible.',
        );
      },
    );

    test(
      'fabric_from_cotton IS assigned once cotton_weaving is unlocked',
      () {
        final plan = planFor(const {kTechIdCottonWeaving: true});
        expect(
          _assignedRecipeIds(plan),
          contains(ProductionRecipesCatalog.fabricFromCotton.id),
          reason: 'With cotton_weaving unlocked and cotton on hand, the only '
              'feasible fabric recipe (fabric_from_cotton) must be assigned.',
        );
      },
    );

    test('gating is deterministic across identical runs', () {
      const tech = {kTechIdCottonWeaving: true};
      expect(_assignedRecipeIds(planFor(tech)), equals(_assignedRecipeIds(planFor(tech))));
      expect(_assignedRecipeIds(planFor(null)), equals(_assignedRecipeIds(planFor(null))));
    });
  });
}
