import 'conquest_move_scoring_context.dart';
import 'conquest_planner_destination_scoring.dart';
import 'conquest_planner_invadable_ids.dart';
import 'conquest_planner_stalled_fallback.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../perception/perception_snapshot.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

Orders runConquestArmyMovePlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
  PhasePlanOutcome? phasePlan,
}) {
  PhaseConquestInvadableResolution? conquestResolution;
  if (phasePlan != null) {
    conquestResolution = resolvePhaseConquestInvadable(
      phasePlan: phasePlan,
      snapshot: snapshot,
      game: ctx.game,
    );
    if (conquestResolution.skipConquestPass) {
      return ctx.orders;
    }
  }

  final invadableForPass = invadableProvinceIdsForConquestPass(
    game: ctx.game,
    snapshot: snapshot,
    phasePlan: phasePlan,
    conquestResolution: conquestResolution,
  );
  final phasePlanInvadableIsAuthoritative =
      conquestResolution != null && !conquestResolution.useLegacyInvadable;
  final colonialPressureActive = phasePlan != null
      ? resolvePhaseConquestColonialPressureActive(phasePlan: phasePlan)
      : hasColonialAcquisitionTargets(snapshot.colonial);
  final nwInvasionWeight = phasePlan != null
      ? resolvePhaseConquestNwInvasionWeight(phasePlan: phasePlan)
      : (shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
              snapshot: snapshot,
              game: ctx.game,
            )
            ? 0.0
            : 1.0);
  final oldWorldInvasionWeight = phasePlan != null
      ? resolvePhaseConquestOldWorldInvasionWeight(phasePlan: phasePlan)
      : 1.0;

  final stalledExpansion = isObserverConquestExpansionPressure(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  // Refs #2847 § EXPAND feedstock-tile acquisition conquest army-move target
  // bias (`SPEC/ai/economy-planner.md`). A flagged below-quota zero-NW
  // lock-recovery seller is always below quota and therefore always on the
  // stalled-expansion army-move path, so the conquest-target bias is computed
  // once here and threaded into the stalled selection helpers only. It returns
  // `null` for every player whose acquisition residual is inactive (so the +6
  // Old World conquest baseline GPs gp1/gp2 are never redirected) and for any
  // non-stalled caller, which never reaches the biased selection path.
  final feedstockConquestTarget = stalledExpansion
      ? expandSellerFeedstockTileAcquisitionTarget(
          game: ctx.game,
          snapshot: snapshot,
        )
      : null;
  final stalledScoringCtx = stalledExpansion
      ? ConquestMoveScoringContext.forArmyMovePass(
          plannerCtx: ctx,
          snapshot: snapshot,
          invadable: invadableForPass,
          stalledExpansion: true,
          declaredWarTargetFactionId: declaredWarTargetFactionId,
          phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
          nwInvasionWeight: nwInvasionWeight,
          oldWorldInvasionWeight: oldWorldInvasionWeight,
        )
      : null;
  final armyMoveCandidates = ctx.suggestionAPI.suggestArmyMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  if (armyMoveCandidates.isEmpty) {
    if (_log.debugEnabled) {
      _log.d('conquest army move nationId=${ctx.nationId} candidatesCount=0');
    }
    if (stalledExpansion) {
      return runStalledFrontierArmyMoveFallback(
        ctx: ctx,
        scoringCtx: stalledScoringCtx!,
        feedstockConquestTarget: feedstockConquestTarget,
      );
    }
    return ctx.orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    ctx.game,
    ctx.nationId,
    armyMoveCandidates,
    draftOrders: ctx.orders,
  );
  if (filtered.isEmpty) {
    if (_log.debugEnabled) {
      _log.d('conquest army move filtered empty nationId=${ctx.nationId}');
    }
    if (stalledExpansion) {
      return runStalledFrontierArmyMoveFallback(
        ctx: ctx,
        scoringCtx: stalledScoringCtx!,
        feedstockConquestTarget: feedstockConquestTarget,
      );
    }
    return ctx.orders;
  }
  final weight = resolveConquestArmyMoveWeight(
    ctx: ctx,
    snapshot: snapshot,
    stalledExpansion: stalledExpansion,
    colonialPressureActive: colonialPressureActive,
    phasePlan: phasePlan,
  );
  if (weight < 10) {
    if (_log.debugEnabled) {
      _log.d(
        'conquest army move skipped nationId=${ctx.nationId} weight=$weight',
      );
    }
    return ctx.orders;
  }
  // Under stalled-expansion (Refs #2509 EXPAND / COLONIAL-lite hot path) a
  // capital field army frequently has no direct neighbor in the phase plan's
  // invadable set — e.g. seed-42 gp1's two field armies at `oldWorld|p12`
  // produce 12 diplomacy-passed candidates that all land on gp1-owned
  // provinces (`p1, p4, p5, p7, p8, p9`), none of which appear in
  // `invadableForPass = {p11, p13, p2}`. The strict invadable-only prefilter
  // here would empty `scoringCandidates`, the planner would return without
  // emitting any army move, and the capital armies sit at the capital across
  // every turn of the 100-turn observer run (gp1 OW gain = 0 against the
  // turn-100 +3 gate). Bypass the prefilter on the stalled-expansion path so
  // the stalled-expansion scoring in `scoreArmyMoveDestination` (which
  // already prefers invadable destinations first, then own-territory
  // adjacent-at-war-frontier marches via
  // `stalledExpansionArmyMoveScoreDelta`, and structurally returns `0` for
  // foreign non-invadable destinations) picks the best multi-turn approach
  // move toward the at-war frontier instead. Non-stalled (at-quota) callers
  // keep the strict prefilter so DEVELOP / COLONIAL stay structural.
  final scoringCandidates =
      phasePlanInvadableIsAuthoritative && !stalledExpansion
      ? filtered
            .where(
              (move) => invadableForPass.contains(move.destinationProvinceId),
            )
            .toList()
      : filtered;
  if (scoringCandidates.isEmpty) {
    return ctx.orders;
  }
  if (stalledExpansion) {
    return applyStalledArmyMovesForAllFieldArmies(
      ctx: ctx,
      scoringCtx: stalledScoringCtx!,
      filtered: scoringCandidates,
      feedstockConquestTarget: feedstockConquestTarget,
    );
  }
  final scoringCtx = ConquestMoveScoringContext.forArmyMovePass(
    plannerCtx: ctx,
    snapshot: snapshot,
    invadable: invadableForPass,
    stalledExpansion: false,
    declaredWarTargetFactionId: declaredWarTargetFactionId,
    phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
    nwInvasionWeight: nwInvasionWeight,
    oldWorldInvasionWeight: oldWorldInvasionWeight,
  );
  final selected = selectWeightedCandidate(
    candidates: scoringCandidates,
    seed: ctx.seeds.militarySeed + 4000,
    score: (m) => scoreArmyMoveDestination(scoringCtx, m),
  );
  if (selected == null) return ctx.orders;
  if (_log.infoEnabled) {
    _log.i(
      'conquest army move chosen nationId=${ctx.nationId} '
      'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId} '
      'declaredWarTarget=$declaredWarTargetFactionId',
    );
  }
  return applyArmyMoveOrderForPlayer(ctx.orders, ctx.nationId, selected);
}
