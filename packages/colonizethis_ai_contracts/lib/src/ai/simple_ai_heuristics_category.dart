// Category selection helpers for simple AI heuristics (Refs #4084 Slice B).
// Former library-private helpers; leading `_` dropped so sibling libraries
// can import them. Behaviour-preserving bodies.

import 'dart:math' as math;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';

/// Suggestion families considered by [generateOrdersWithSimpleHeuristics].
enum SimpleHeuristicSuggestionCategory { moves, work, build, research }

/// Picks the next suggestion category. When both move and work have candidates,
/// uses [rng] so work (e.g. `build_rail` with tile maps) is not always starved.
/// SPEC/program/sim-game-default-ai.md, ai-planner.md.
SimpleHeuristicSuggestionCategory chooseSuggestionCategory(
  List<SimpleHeuristicSuggestionCategory> categories,
  math.Random rng,
) {
  categories.sort((a, b) => a.index.compareTo(b.index));
  final hasMoves = categories.contains(SimpleHeuristicSuggestionCategory.moves);
  final hasWork = categories.contains(SimpleHeuristicSuggestionCategory.work);
  if (hasMoves && hasWork) {
    return rng.nextBool()
        ? SimpleHeuristicSuggestionCategory.moves
        : SimpleHeuristicSuggestionCategory.work;
  }
  return categories.first;
}

List<SimpleHeuristicSuggestionCategory> categoriesPresent({
  required List<MoveOrder> moveSuggestions,
  required List<ArmyMoveOrder> armyMoveSuggestions,
  required List<WorkOrder> workSuggestions,
  required List<BuildUnitOrder> buildSuggestions,
  required List<ResearchOrder> researchSuggestions,
}) {
  final categories = <SimpleHeuristicSuggestionCategory>[];
  if (moveSuggestions.isNotEmpty || armyMoveSuggestions.isNotEmpty) {
    categories.add(SimpleHeuristicSuggestionCategory.moves);
  }
  if (workSuggestions.isNotEmpty) {
    categories.add(SimpleHeuristicSuggestionCategory.work);
  }
  if (buildSuggestions.isNotEmpty) {
    categories.add(SimpleHeuristicSuggestionCategory.build);
  }
  if (researchSuggestions.isNotEmpty) {
    categories.add(SimpleHeuristicSuggestionCategory.research);
  }
  return categories;
}

SimpleHeuristicSuggestionCategory resolveSimpleHeuristicCategory({
  required List<SimpleHeuristicSuggestionCategory> categories,
  required List<WorkOrder> workSuggestions,
  required math.Random rng,
}) {
  if (categories.contains(SimpleHeuristicSuggestionCategory.moves) &&
      categories.contains(SimpleHeuristicSuggestionCategory.work) &&
      workSuggestions.any((w) => w.target == kWorkTargetBuildRail)) {
    return SimpleHeuristicSuggestionCategory.work;
  }
  return chooseSuggestionCategory(
    List<SimpleHeuristicSuggestionCategory>.from(categories),
    rng,
  );
}
