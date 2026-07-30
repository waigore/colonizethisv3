// AI core labour allocation matches shared industry counsel core (Refs #4189).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/economy_planner_labour.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
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
  });
}
