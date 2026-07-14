// Naval combat resolve/apply. Types and detection live in sibling modules.
// SPEC/program/naval-combat-resolution.md; SPEC/game/ships-and-naval.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'combat_rng.dart';
import 'military_strength.dart';
import 'naval_combat_types.dart';

export 'naval_combat_detection.dart';
export 'naval_combat_types.dart';

/// Average movement (MV) for a list of ship types. Used for retreat speed advantage.
double avgNavalMovement(List<String> shipTypeIds) {
  if (shipTypeIds.isEmpty) return 0.0;
  var sum = 0.0;
  for (final id in shipTypeIds) {
    sum += NavalStatsCatalog.get(id).movement;
  }
  return sum / shipTypeIds.length;
}

/// Compute naval strength from ship type list (firepower + range weighted).
double navalStrength(List<String> shipTypeIds) {
  var total = 0.0;
  for (final typeId in shipTypeIds) {
    total += NavalStatsCatalog.shipStrength(typeId);
  }
  return total;
}

/// Resolve one sea battle deterministically. Seed from game + zone for RNG.
/// Applies retreat roll per SPEC/game/ships-and-naval.md (base 0.6 + speed advantage - enemy mission aggression term).
NavalBattleResult resolveSeaBattle(
  BattleContextSea battle,
  int seed, {
  bool side1CanRetreat = true,
  bool side2CanRetreat = true,
  Map<String, double> navalFeedingCoverageByPlayerId = const {},
}) {
  final rng = navalCombatRng(seed);
  final cov1 = navalFeedingCoverageByPlayerId[battle.side1.ownerId] ?? 1.0;
  final cov2 = navalFeedingCoverageByPlayerId[battle.side2.ownerId] ?? 1.0;
  final m1 = moraleMultiplierForFeedingCoverage(cov1);
  final m2 = moraleMultiplierForFeedingCoverage(cov2);
  final str1 = navalStrength(battle.side1.shipTypeIds) * m1;
  final str2 = navalStrength(battle.side2.shipTypeIds) * m2;
  final total = str1 + str2;
  if (total <= 0) {
    return NavalBattleResult(
      survivingShipsSide1: copyNavalShips(battle.side1.ships),
      survivingShipsSide2: copyNavalShips(battle.side2.ships),
    );
  }
  final ratio1 = str1 / total;
  final casualties1 = (battle.side1.ships.length * (1 - ratio1) * 0.5)
      .round()
      .clamp(0, battle.side1.ships.length);
  final casualties2 = (battle.side2.ships.length * (1 - (1 - ratio1)) * 0.5)
      .round()
      .clamp(0, battle.side2.ships.length);
  final list1 = copyNavalShips(battle.side1.ships);
  final list2 = copyNavalShips(battle.side2.ships);
  for (var i = 0; i < casualties1 && list1.isNotEmpty; i++) {
    list1.removeAt(rng.nextInt(list1.length));
  }
  for (var i = 0; i < casualties2 && list2.isNotEmpty; i++) {
    list2.removeAt(rng.nextInt(list2.length));
  }

  bool side1Retreated = false;
  bool side2Retreated = false;
  final mv1 = avgNavalMovement(battle.side1.shipTypeIds);
  final mv2 = avgNavalMovement(battle.side2.shipTypeIds);
  final speedAdvantage1 = (mv1 - mv2) * kNavalRetreatSpeedFactor;
  final speedAdvantage2 = (mv2 - mv1) * kNavalRetreatSpeedFactor;
  final enemyAggression1 = battle.side2.mission == FleetMission.blockade
      ? kNavalRetreatEnemyBlockade
      : (battle.side2.mission == FleetMission.patrol
            ? kNavalRetreatEnemyPatrol
            : 0.0);
  final enemyAggression2 = battle.side1.mission == FleetMission.blockade
      ? kNavalRetreatEnemyBlockade
      : (battle.side1.mission == FleetMission.patrol
            ? kNavalRetreatEnemyPatrol
            : 0.0);
  final pRetreat1 =
      (kNavalRetreatBaseChance + speedAdvantage1 - enemyAggression1).clamp(
        0.1,
        0.95,
      );
  final pRetreat2 =
      (kNavalRetreatBaseChance + speedAdvantage2 - enemyAggression2).clamp(
        0.1,
        0.95,
      );
  if (side1CanRetreat &&
      list1.isNotEmpty &&
      rng.nextInt(100) < (pRetreat1 * 100).round())
    side1Retreated = true;
  if (side2CanRetreat &&
      list2.isNotEmpty &&
      rng.nextInt(100) < (pRetreat2 * 100).round())
    side2Retreated = true;

  NavalBattleOutcome outcome = NavalBattleOutcome.stalemate;
  if (list1.isEmpty && list2.isEmpty) {
    outcome = NavalBattleOutcome.mutualDestruction;
  } else if (list1.isEmpty && list2.isNotEmpty) {
    outcome = NavalBattleOutcome.side2Victory;
  } else if (list2.isEmpty && list1.isNotEmpty) {
    outcome = NavalBattleOutcome.side1Victory;
  }

  combatLog.d(
    'naval battle zone=${battle.seaZoneId} side1=${battle.side1.ownerId} side2=${battle.side2.ownerId} '
    'outcome=${outcome.name} retreat1=$side1Retreated retreat2=$side2Retreated',
  );

  return NavalBattleResult(
    survivingShipsSide1: list1,
    survivingShipsSide2: list2,
    side1Retreated: side1Retreated,
    side2Retreated: side2Retreated,
    outcome: outcome,
  );
}

/// Apply naval battle results to game: replace all fleets of both sides in zone with surviving fleets.
/// If retreat destination is provided and side retreated, that side's fleet is placed in that zone.
Game applyNavalBattleResults(
  Game game,
  BattleContextSea battle,
  NavalBattleResult result,
  String regionIdForZone, {
  String? retreatDestinationSide1,
  String? retreatDestinationSide2,
}) {
  var fleets = List<Fleet>.from(game.worldState.fleets);
  final zone = battle.seaZoneId;
  final owner1 = battle.side1.ownerId;
  final owner2 = battle.side2.ownerId;

  fleets = fleets
      .where(
        (f) =>
            !f.isAtSea ||
            f.seaZoneId != zone ||
            (f.ownerId != owner1 && f.ownerId != owner2),
      )
      .toList();

  var zone1 = zone;
  var zone2 = zone;
  if (result.side1Retreated && retreatDestinationSide1 != null)
    zone1 = retreatDestinationSide1;
  if (result.side2Retreated && retreatDestinationSide2 != null)
    zone2 = retreatDestinationSide2;

  if (result.survivingShipsSide1.isNotEmpty) {
    fleets.add(
      Fleet(
        id: 'naval_${owner1}_$zone1',
        ownerId: owner1,
        seaZoneId: zone1,
        inPortAtProvinceId: null,
        regionId: regionIdForZone,
        ships: result.survivingShipsSide1,
        mission: battle.side1.mission,
      ),
    );
  }
  if (result.survivingShipsSide2.isNotEmpty) {
    fleets.add(
      Fleet(
        id: 'naval_${owner2}_$zone2',
        ownerId: owner2,
        seaZoneId: zone2,
        inPortAtProvinceId: null,
        regionId: regionIdForZone,
        ships: result.survivingShipsSide2,
        mission: battle.side2.mission,
      ),
    );
  }
  return game.withFleets(fleets);
}
