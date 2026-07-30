// AI core labour allocation matches shared industry counsel core (Refs #4189).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/economy_planner_labour.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/industry_counsel_ranking.dart';
import 'package:colonizethis_test/test.dart';

const _coreOnlyConfig = AIConfig(
  leaderId: 'gp1',
  personalityId: 'victoria',
  hiddenAgendaId: kIndustryCounselNeutralAgendaId,
);

final _coreOnlySeeds = AISeedBundle.fromTurnSeed(42);

LabourAllocationInput _coreOnlyInput({
  required Stockpile stockpile,
  required WorkerPool workers,
  required int effectiveLabour,
  Map<String, bool>? techUnlocked,
}) {
  return LabourAllocationInput(
    stockpile: stockpile,
    workers: workers,
    effectiveLabour: effectiveLabour,
    config: _coreOnlyConfig,
    seeds: _coreOnlySeeds,
    techUnlocked: techUnlocked,
  );
}

List<AssignedRecipe> _sortedAssignments(List<AssignedRecipe> assignments) {
  final copy = [...assignments];
  copy.sort((a, b) => a.recipeId.compareTo(b.recipeId));
  return copy;
}

Map<String, int> _assignmentLabourByRecipe(List<AssignedRecipe> assignments) {
  return {
    for (final assignment in assignments)
      assignment.recipeId: assignment.assignedLabour,
  };
}

void _expectSameAssignments(
  List<AssignedRecipe> actual,
  List<AssignedRecipe> expected,
) {
  expect(
    _assignmentLabourByRecipe(_sortedAssignments(actual)),
    _assignmentLabourByRecipe(_sortedAssignments(expected)),
  );
}

void main() {
  group('allocateLabour core path characterization', () {
    test('matches industryCounselAllocateLabourCore with timber and labour', () {
      final stockpile = Stockpile().applyDelta(CommodityCatalog.timber.id, 30);
      const workers = WorkerPool(peasants: 4);
      const effectiveLabour = 8;
      final input = _coreOnlyInput(
        stockpile: stockpile,
        workers: workers,
        effectiveLabour: effectiveLabour,
      );

      final aiAssignments = allocateLabour(input);
      final coreAssignments = industryCounselAllocateLabourCore(
        stockpile: stockpile,
        workers: workers,
        effectiveLabour: effectiveLabour,
        techUnlocked: null,
        agendaId: kIndustryCounselNeutralAgendaId,
      );

      _expectSameAssignments(aiAssignments, coreAssignments);
      expect(aiAssignments, isNotEmpty);
    });

    test('matches core allocator when no feasible recipes', () {
      final input = LabourAllocationInput(
        stockpile: const Stockpile(),
        workers: const WorkerPool(),
        effectiveLabour: 0,
        config: _coreOnlyConfig,
        seeds: _coreOnlySeeds,
      );

      expect(
        _assignmentLabourByRecipe(allocateLabour(input)),
        _assignmentLabourByRecipe(
          industryCounselAllocateLabourCore(
            stockpile: input.stockpile,
            workers: input.workers,
            effectiveLabour: input.effectiveLabour,
            techUnlocked: null,
            agendaId: kIndustryCounselNeutralAgendaId,
          ),
        ),
      );
    });

    test('H8 regiment boost diverges from core but counsel uses core scores', () {
      final stockpile = Stockpile()
          .applyDelta(CommodityCatalog.timber.id, 50)
          .applyDelta(CommodityCatalog.cotton.id, 50);
      const workers = WorkerPool(peasants: 6);
      const effectiveLabour = 24;
      const techUnlocked = {kTechIdCottonWeaving: true};
      final coreInput = LabourAllocationInput(
        stockpile: stockpile,
        workers: workers,
        effectiveLabour: effectiveLabour,
        config: _coreOnlyConfig,
        seeds: _coreOnlySeeds,
        techUnlocked: techUnlocked,
      );
      final boostedInput = LabourAllocationInput(
        stockpile: stockpile,
        workers: workers,
        effectiveLabour: effectiveLabour,
        config: _coreOnlyConfig,
        seeds: _coreOnlySeeds,
        techUnlocked: techUnlocked,
        regimentBuildInputProductionBoost: true,
        missingRegimentBuildInputIds: {CommodityCatalog.fabric.id},
      );

      final coreAssignments = allocateLabour(coreInput);
      final boostedAssignments = allocateLabour(boostedInput);
      expect(
        _assignmentLabourByRecipe(boostedAssignments),
        isNot(equals(_assignmentLabourByRecipe(coreAssignments))),
      );

      final game = Game(
        id: 'g-h8-negative',
        players: [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: true,
            stockpile: stockpile,
            workerPool: workers,
            techUnlocked: techUnlocked,
          ),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
      );
      final ranked = rankIndustryCounselRecommendations(
        game: game,
        playerId: 'gp1',
        currentOrders: const Orders(),
        topology: const MapTopology(),
        tileMapByRegion: const {},
      );
      for (final rec in ranked) {
        if (rec.kind != IndustryCounselRecommendationKind.produceRecipe) {
          continue;
        }
        final recipe = ProductionRecipesCatalog.byId[rec.recipeId];
        expect(recipe, isNotNull);
        expect(
          rec.rankScore,
          industryCounselScoreRecipe(
            recipe: recipe!,
            stockpile: stockpile,
            workers: workers,
            agendaId: kIndustryCounselNeutralAgendaId,
          ),
        );
      }
    });
  });
}
