/// Quick Battle group bookkeeping and command-point limits.
///
/// SPEC/program/quick-battle-resolution.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_survivor_units.dart';

/// Keep (copy-disposition, Refs #3448 AC5): canonical working-copy helper for
/// Quick Battle. Groups (and their `unitIds`) are mutated per round, so each
/// run must own detached lists rather than alias the caller's deployment. This
/// is a unit-id clone, not a [ShipInstance] clone, so it stays distinct from
/// `copyNavalShips(...)`.
List<QuickBattleGroup> copyGroups(List<QuickBattleGroup> groups) => groups
    .map((g) => g.copyWith(unitIds: List<String>.from(g.unitIds)))
    .toList();

int rollCommandPoints(Random rng) {
  final span = quickBattleCpPerRoundMax - quickBattleCpPerRoundMin;
  if (span <= 0) return quickBattleCpPerRoundMin;
  return quickBattleCpPerRoundMin + rng.nextInt(span + 1);
}

int _actionCost(QuickBattleAction action) {
  switch (action) {
    case QuickBattleAction.volleyFire:
    case QuickBattleAction.defendEntrench:
    case QuickBattleAction.maneuver:
      return 1;
    case QuickBattleAction.fallBackRefuseFlank:
    case QuickBattleAction.assaultCharge:
      return 2;
  }
}

List<QuickBattleAction> limitActionsByCp(
  List<QuickBattleAction> actions,
  int cp,
) {
  final result = <QuickBattleAction>[];
  var spent = 0;
  for (final a in actions) {
    final cost = _actionCost(a);
    if (spent + cost > cp) break;
    result.add(a);
    spent += cost;
  }
  return result;
}

List<String> pickCasualties(
  List<QuickBattleGroup> groups,
  double fraction,
  Random rng,
) {
  final allIds = <String>[];
  for (final g in groups) {
    allIds.addAll(g.unitIds);
  }
  if (allIds.isEmpty) return [];
  final count = (allIds.length * fraction).ceil().clamp(0, allIds.length);
  allIds.shuffle(rng);
  return allIds.take(count).toList();
}

List<QuickBattleGroup> removeCasualties(
  List<QuickBattleGroup> groups,
  List<String> casualties,
) {
  final casualtySet = casualties.toSet();
  return groups
      .map(
        (g) => g.copyWith(
          unitIds: idsExcludingCasualtyIds(g.unitIds, casualtySet).toList(),
        ),
      )
      .where((g) => g.unitIds.isNotEmpty)
      .toList();
}

List<QuickBattleGroup> degradeCohesion(List<QuickBattleGroup> groups) {
  return groups
      .map(
        (g) => g.copyWith(
          cohesion: (g.cohesion - 1).clamp(0, quickBattleMaxCohesion),
        ),
      )
      .toList();
}

int totalUnitCount(List<QuickBattleGroup> groups) =>
    groups.fold(0, (s, g) => s + g.unitIds.length);
