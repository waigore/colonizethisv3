// Naval combat: conflict detection, BattleContextSea, resolve. SPEC/program/naval-combat-resolution.md.
// Interception and retreat: SPEC/game/ships-and-naval.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_combat/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'deterministic_rng.dart';
import 'military_strength.dart';

/// Mission factor for Patrol interception probability.
const double kNavalInterceptMissionFactorPatrol = 0.50;

/// Mission factor for Blockade interception probability.
const double kNavalInterceptMissionFactorBlockade = 0.90;

/// Retreat base chance. SPEC/game/ships-and-naval.md.
const double kNavalRetreatBaseChance = 0.6;

/// Retreat speed advantage factor per MV point difference.
const double kNavalRetreatSpeedFactor = 0.1;

/// Enemy aggression when enemy is on Patrol.
const double kNavalRetreatEnemyPatrol = 0.1;

/// Enemy aggression when enemy is on Blockade.
const double kNavalRetreatEnemyBlockade = 0.2;

/// One side in a sea battle: owner, ship instances, mission (used for retreat `enemyAggression` from opponent mission).
class NavalBattleSide {
  const NavalBattleSide({
    required this.ownerId,
    required this.ships,
    this.mission = FleetMission.none,
  });

  final String ownerId;
  final List<ShipInstance> ships;
  final FleetMission mission;

  /// Type id per ship (combat aggregation).
  List<String> get shipTypeIds => ships.map((s) => s.typeId).toList();
}

/// Sea battle context for one zone. SPEC/program/naval-combat-resolution.md.
///
/// After [normalizeNavalBattleSidesForAttacker], [side1] is the **attacker** and [side2] is the **defender**.
class BattleContextSea {
  const BattleContextSea({
    required this.seaZoneId,
    required this.side1,
    required this.side2,
  });

  final String seaZoneId;
  final NavalBattleSide side1;
  final NavalBattleSide side2;
}

bool _ownerHadMovingFleetInZone(
  Game game,
  String seaZoneId,
  String ownerId,
  Set<String> movedFleetIds,
) {
  if (movedFleetIds.isEmpty) return false;
  return game.worldState.fleets.any(
    (f) =>
        f.isAtSea &&
        f.seaZoneId == seaZoneId &&
        f.ownerId == ownerId &&
        movedFleetIds.contains(f.id),
  );
}

bool _isInterceptorMission(FleetMission m) =>
    m == FleetMission.patrol || m == FleetMission.blockade;

bool _navalBattleShouldSwapAttackerSides({
  required bool m1,
  required bool m2,
  required bool int1,
  required bool int2,
  required String s1OwnerId,
  required String s2OwnerId,
}) {
  if (m1 && !m2 && int2) return true;
  if (m2 && !m1 && int1) return false;
  if (m1 && !m2) return false;
  if (m2 && !m1) return true;
  return s1OwnerId.compareTo(s2OwnerId) > 0;
}

/// Orders [battle] so [side1] is the attacker and [side2] is the defender per SPEC/program/naval-combat-resolution.md.
///
/// Precedence: (1) If exactly one faction moved into the zone and the other is on Patrol or Blockade, the interceptor is the attacker. (2) Else if exactly one faction moved, the mover is the attacker. (3) Else (both moved, or neither) use lexicographically smaller `ownerId` as attacker for deterministic ordering.
BattleContextSea normalizeNavalBattleSidesForAttacker(
  BattleContextSea battle,
  Game game,
  Set<String> movedFleetIds,
) {
  final s1 = battle.side1;
  final s2 = battle.side2;
  final m1 = _ownerHadMovingFleetInZone(
    game,
    battle.seaZoneId,
    s1.ownerId,
    movedFleetIds,
  );
  final m2 = _ownerHadMovingFleetInZone(
    game,
    battle.seaZoneId,
    s2.ownerId,
    movedFleetIds,
  );
  final int1 = _isInterceptorMission(s1.mission);
  final int2 = _isInterceptorMission(s2.mission);

  final swap = _navalBattleShouldSwapAttackerSides(
    m1: m1,
    m2: m2,
    int1: int1,
    int2: int2,
    s1OwnerId: s1.ownerId,
    s2OwnerId: s2.ownerId,
  );

  if (!swap) {
    return battle;
  }
  return BattleContextSea(seaZoneId: battle.seaZoneId, side1: s2, side2: s1);
}

/// Conflict detection: returns contested sea zones with two hostile sides.
/// Populates mission per side from fleet state for retreat aggression.
List<BattleContextSea> detectNavalConflicts(Game game) {
  final atWar = hostileFactionsByFaction(game);
  final byZone = <String, Map<String, List<ShipInstance>>>{};
  final missionByZoneOwner = <String, Map<String, FleetMission>>{};
  for (final f in game.worldState.fleets) {
    if (!f.isAtSea || f.seaZoneId == null)
      continue; // Naval combat only in sea zones. SPEC/game/ships-and-naval.md.
    final zoneId = f.seaZoneId!;
    byZone.putIfAbsent(zoneId, () => {});
    byZone[zoneId]!.putIfAbsent(f.ownerId, () => []).addAll(f.ships);
    missionByZoneOwner.putIfAbsent(zoneId, () => {});
    missionByZoneOwner[zoneId]!.putIfAbsent(f.ownerId, () => f.mission);
  }
  final result = <BattleContextSea>[];
  for (final entry in byZone.entries) {
    final zoneId = entry.key;
    final owners = entry.value;
    if (owners.length < 2) continue;
    final ownerList = owners.keys.toList();
    bool added = false;
    for (var i = 0; i < ownerList.length && !added; i++) {
      for (var j = i + 1; j < ownerList.length && !added; j++) {
        final a = ownerList[i];
        final b = ownerList[j];
        if (atWar[a]?.contains(b) != true) continue;
        final missionA = missionByZoneOwner[zoneId]?[a] ?? FleetMission.none;
        final missionB = missionByZoneOwner[zoneId]?[b] ?? FleetMission.none;
        result.add(
          BattleContextSea(
            seaZoneId: zoneId,
            side1: NavalBattleSide(
              ownerId: a,
              ships: List.from(owners[a]!),
              mission: missionA,
            ),
            side2: NavalBattleSide(
              ownerId: b,
              ships: List.from(owners[b]!),
              mission: missionB,
            ),
          ),
        );
        added = true;
      }
    }
  }
  return result;
}

(double intercept, double flee) _fleetInterceptAndFleeScores(
  List<String> shipTypeIds,
) {
  var intercept = 0.0;
  var flee = 0.0;
  for (final id in shipTypeIds) {
    final stats = NavalStatsCatalog.get(id);
    intercept += stats.interceptRating;
    flee += stats.fleeRating;
  }
  return (intercept, flee);
}

/// Interception probability from mission factor × (intercept / (intercept + flee)).
/// Clamped to [0.05, 0.85].
double navalInterceptProbability({
  required double interceptorScore,
  required double targetFleeScore,
  required bool isBlockade,
}) {
  final denom = interceptorScore + targetFleeScore;
  final ratio = denom <= 0 ? 0.0 : interceptorScore / denom;
  final missionFactor = isBlockade
      ? kNavalInterceptMissionFactorBlockade
      : kNavalInterceptMissionFactorPatrol;
  return (missionFactor * ratio).clamp(0.05, 0.85);
}

/// Average movement (MV) for a list of ship types. Used for retreat speed advantage.
double avgNavalMovement(List<String> shipTypeIds) {
  if (shipTypeIds.isEmpty) return 0.0;
  var sum = 0.0;
  for (final id in shipTypeIds) {
    sum += NavalStatsCatalog.get(id).movement;
  }
  return sum / shipTypeIds.length;
}

/// Filter battles by interception roll when one side moved and the other is Patrol/Blockade.
/// [movedFleetIds] = set of fleet ids that had a move order this turn.
/// Returns only battles where interceptor rolled success (or no interception case).
List<BattleContextSea> filterBattlesByInterception(
  Game game,
  List<BattleContextSea> battles,
  Set<String> movedFleetIds,
  int seed,
) {
  if (battles.isEmpty) return battles;
  final rng = DeterministicRng(seed);

  // Pre-index moved fleets at sea by (seaZoneId, ownerId) to avoid O(fleets)
  // scan per battle.
  final movedAtSeaByZoneAndOwner = <String, Set<String>>{};
  for (final f in game.worldState.fleets) {
    if (!f.isAtSea || f.seaZoneId == null) continue;
    if (!movedFleetIds.contains(f.id)) continue;
    movedAtSeaByZoneAndOwner
        .putIfAbsent('${f.seaZoneId}|${f.ownerId}', () => {})
        .add(f.id);
  }

  bool ownerMovedInZone(String ownerId, String zone) =>
      movedAtSeaByZoneAndOwner.containsKey('$zone|$ownerId');

  final out = <BattleContextSea>[];
  for (final battle in battles) {
    final zone = battle.seaZoneId;
    final owner1Moved = ownerMovedInZone(battle.side1.ownerId, zone);
    final owner2Moved = ownerMovedInZone(battle.side2.ownerId, zone);
    final (side1InterceptScore, side1FleeScore) = _fleetInterceptAndFleeScores(
      battle.side1.shipTypeIds,
    );
    final (side2InterceptScore, side2FleeScore) = _fleetInterceptAndFleeScores(
      battle.side2.shipTypeIds,
    );
    final side2IsInterceptor =
        battle.side2.mission == FleetMission.patrol ||
        battle.side2.mission == FleetMission.blockade;
    final side1IsInterceptor =
        battle.side1.mission == FleetMission.patrol ||
        battle.side1.mission == FleetMission.blockade;
    bool rollIntercept = false;
    double pIntercept = 0.5;
    if (owner1Moved && side2IsInterceptor) {
      rollIntercept = true;
      pIntercept = navalInterceptProbability(
        interceptorScore: side2InterceptScore,
        targetFleeScore: side1FleeScore,
        isBlockade: battle.side2.mission == FleetMission.blockade,
      );
    } else if (owner2Moved && side1IsInterceptor) {
      rollIntercept = true;
      pIntercept = navalInterceptProbability(
        interceptorScore: side1InterceptScore,
        targetFleeScore: side2FleeScore,
        isBlockade: battle.side1.mission == FleetMission.blockade,
      );
    }
    if (!rollIntercept) {
      out.add(battle);
      continue;
    }
    final roll = rng.nextInt(100) / 100.0;
    if (roll < pIntercept) out.add(battle);
  }
  return out;
}

/// Compute naval strength from ship type list (firepower + range weighted).
double navalStrength(List<String> shipTypeIds) {
  var total = 0.0;
  for (final typeId in shipTypeIds) {
    total += NavalStatsCatalog.shipStrength(typeId);
  }
  return total;
}

enum NavalBattleOutcome {
  side1Victory,
  side2Victory,
  stalemate,
  mutualDestruction,
}

/// Result of resolving one sea battle: updated fleet lists (sunk ships removed).
class NavalBattleResult {
  const NavalBattleResult({
    required this.survivingShipsSide1,
    required this.survivingShipsSide2,
    this.side1Retreated = false,
    this.side2Retreated = false,
    this.outcome = NavalBattleOutcome.stalemate,
  });

  final List<ShipInstance> survivingShipsSide1;
  final List<ShipInstance> survivingShipsSide2;
  final bool side1Retreated;
  final bool side2Retreated;
  final NavalBattleOutcome outcome;
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
  final rng = DeterministicRng(seed);
  final cov1 = navalFeedingCoverageByPlayerId[battle.side1.ownerId] ?? 1.0;
  final cov2 = navalFeedingCoverageByPlayerId[battle.side2.ownerId] ?? 1.0;
  final m1 = moraleMultiplierForFeedingCoverage(cov1);
  final m2 = moraleMultiplierForFeedingCoverage(cov2);
  final str1 = navalStrength(battle.side1.shipTypeIds) * m1;
  final str2 = navalStrength(battle.side2.shipTypeIds) * m2;
  final total = str1 + str2;
  if (total <= 0) {
    return NavalBattleResult(
      survivingShipsSide1: List.from(battle.side1.ships),
      survivingShipsSide2: List.from(battle.side2.ships),
    );
  }
  final ratio1 = str1 / total;
  final casualties1 = (battle.side1.ships.length * (1 - ratio1) * 0.5)
      .round()
      .clamp(0, battle.side1.ships.length);
  final casualties2 = (battle.side2.ships.length * (1 - (1 - ratio1)) * 0.5)
      .round()
      .clamp(0, battle.side2.ships.length);
  final list1 = List<ShipInstance>.from(battle.side1.ships);
  final list2 = List<ShipInstance>.from(battle.side2.ships);
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
