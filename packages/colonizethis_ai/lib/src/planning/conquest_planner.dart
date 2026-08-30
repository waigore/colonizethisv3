import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart'
    show factionOwnsInvadableOldWorldProvince, minorAtWarPeaceTargetsWhere;
import 'planning_imports.dart';

export 'conquest_planner_army_move.dart' show runConquestArmyMovePlanner;
export 'conquest_planner_destination_scoring.dart'
    show conquestOldWorldArmyMoveScaledBonus, conquestNwInvadableArmyMoveBonus;

/// When Old World expansion is stalled, prefer marching against an at-war minor
/// that still owns invadable provinces over this turn's declare-war target (e.g.
/// a tribe picked while OW minors remain unconquered). Refs #2509.
String? stalledConquestDeclaredWarTarget({
  required Game game,
  required String nationId,
  required AIWorldSnapshot snapshot,
  required String? declaredThisTurn,
}) {
  var activeMinor = belowQuotaActiveMinorWarTarget(
    game: game,
    snapshot: snapshot,
  );
  if (activeMinor == null &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    final atWarMinors = minorAtWarPeaceTargetsWhere(
      game: game,
      snapshot: snapshot,
    );
    if (atWarMinors.length == 1 &&
        snapshot.conquest.oldWorldProvincesOwned <=
            kStalledOldWorldProvinceThreshold) {
      activeMinor = atWarMinors.single;
    }
  }
  if (activeMinor != null && snapshot.threats.atWarWith.contains(activeMinor)) {
    return activeMinor;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final gpBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (gpBlocker != null &&
      snapshot.threats.atWarWith.contains(gpBlocker) &&
      factionOwnsInvadableOldWorldProvince(
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        factionId: gpBlocker,
      )) {
    return gpBlocker;
  }
  if (!isObserverConquestExpansionPressure(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return declaredThisTurn;
  }
  String? bestMinorId;
  var bestInvadableCount = 0;
  for (final minor in game.minorNations) {
    final rel = getRelation(game, nationId, minor.id);
    if (rel?.state != RelationState.atWar) continue;
    final invadableCount = snapshot.conquest.invadableProvinceIdsSorted
        .where((pid) => provinceOwner[pid] == minor.id)
        .length;
    if (invadableCount > bestInvadableCount) {
      bestInvadableCount = invadableCount;
      bestMinorId = minor.id;
    }
  }
  return bestMinorId ?? declaredThisTurn;
}

/// Picks the highest-scoring army move from [candidates], applying the EXPAND
/// feedstock-tile acquisition conquest army-move target **tiebreak** (Refs
/// #2847 § EXPAND feedstock-tile acquisition conquest army-move target bias;
/// `SPEC/ai/economy-planner.md`).
///
/// Scans [candidates] tracking the highest [score]. On an **exact** score tie
/// the candidate whose `destinationProvinceId` equals [feedstockConquestTarget]
/// wins over a non-feedstock incumbent, so a flagged below-quota zero-NW
/// lock-recovery seller marches the field army onto the Old World feedstock
/// province it must acquire to source `lumber` / `castIron` domestically. The
/// tiebreak **never overrides a strictly higher-scored destination** (it only
/// breaks ties) and **never fires when [feedstockConquestTarget] is `null`** —
/// `expandSellerFeedstockTileAcquisitionTarget` returns `null` for every player
/// whose acquisition residual is inactive, so the +6 Old World conquest
/// baseline GPs gp1/gp2 are never redirected. With [feedstockConquestTarget]
/// `null` the selection is identical to a strict `score > best` argmax
/// (first-in-iteration order wins ties), preserving the prior behaviour
/// exactly. Pure and deterministic over [candidates] and [score].
ArmyMoveOrder? selectFeedstockBiasedBestArmyMove({
  required Iterable<ArmyMoveOrder> candidates,
  required double Function(ArmyMoveOrder move) score,
  required String? feedstockConquestTarget,
}) {
  ArmyMoveOrder? best;
  var bestScore = -1.0;
  var bestIsFeedstock = false;
  for (final move in candidates) {
    final moveScore = score(move);
    final isFeedstock =
        feedstockConquestTarget != null &&
        move.destinationProvinceId == feedstockConquestTarget;
    final beatsBest = moveScore > bestScore;
    final winsTiebreak =
        moveScore == bestScore && isFeedstock && !bestIsFeedstock;
    if (beatsBest || winsTiebreak) {
      best = move;
      bestScore = moveScore;
      bestIsFeedstock = isFeedstock;
    }
  }
  return best;
}
