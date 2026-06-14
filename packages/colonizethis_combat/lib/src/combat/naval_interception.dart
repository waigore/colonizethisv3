// Naval movement interception: probability model and battle filtering.
// SPEC/program/naval-movement-resolution.md § Interception.
// Privateering bonus: SPEC/game/ships-and-naval.md, SPEC/game/tech-tree-naval.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'combat_rng.dart';
import 'naval_combat_resolver.dart';

/// Mission factor for Patrol interception probability.
const double kNavalInterceptMissionFactorPatrol = 0.50;

/// Mission factor for Blockade interception probability.
const double kNavalInterceptMissionFactorBlockade = 0.90;

/// Privateering doctrine bonus to movement interception effectiveness.
///
/// Applied as a single multiplicative factor to the intercepting fleet's
/// `fleetInterceptScore` before the `[0.05, 0.85]` clamp, only when the
/// intercepting owner has `privateering_companies` unlocked. Deterministic, no
/// ruleset lookup. SPEC/program/naval-movement-resolution.md § Interception;
/// SPEC/game/tech-tree-naval.md (`privateering_companies`).
const double kPrivateeringInterceptBonus = 1.25;

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
///
/// When [interceptorHasPrivateering] is true, the intercepting fleet's
/// [interceptorScore] is scaled by [kPrivateeringInterceptBonus] before the
/// ratio and clamp, raising effectiveness for owners of `privateering_companies`
/// while leaving the clamp bounds as the hard limits.
/// SPEC/program/naval-movement-resolution.md § Interception.
double navalInterceptProbability({
  required double interceptorScore,
  required double targetFleeScore,
  required bool isBlockade,
  bool interceptorHasPrivateering = false,
}) {
  final effectiveInterceptorScore = interceptorHasPrivateering
      ? interceptorScore * kPrivateeringInterceptBonus
      : interceptorScore;
  final denom = effectiveInterceptorScore + targetFleeScore;
  final ratio = denom <= 0 ? 0.0 : effectiveInterceptorScore / denom;
  final missionFactor = isBlockade
      ? kNavalInterceptMissionFactorBlockade
      : kNavalInterceptMissionFactorPatrol;
  return (missionFactor * ratio).clamp(0.05, 0.85);
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
  final rng = navalCombatRng(seed);

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

  bool ownerHasPrivateering(String ownerId) =>
      game.playerById(ownerId)?.techUnlocked?[kTechIdPrivateeringCompanies] ==
      true;

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
        interceptorHasPrivateering: ownerHasPrivateering(battle.side2.ownerId),
      );
    } else if (owner2Moved && side1IsInterceptor) {
      rollIntercept = true;
      pIntercept = navalInterceptProbability(
        interceptorScore: side1InterceptScore,
        targetFleeScore: side2FleeScore,
        isBlockade: battle.side1.mission == FleetMission.blockade,
        interceptorHasPrivateering: ownerHasPrivateering(battle.side1.ownerId),
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
