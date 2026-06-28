part of 'domain_planner_orchestrator.dart';

/// Military-phase orchestrator slice carrying the post-pass
/// [PlannerContext] plus the conquest army-move gate signals required to
/// populate `thresholds.domainGates` in the AI trace (Refs #2832) and the
/// [DomainPlannerOutcome.conquestArmyMoveCount] surfaced to callers.
class _MilitaryDomainPlannersResult {
  const _MilitaryDomainPlannersResult({
    required this.ctx,
    required this.conquestArmyMovePlannerRan,
    required this.conquestPasses,
    required this.conquestArmyMoveCount,
  });

  final PlannerContext ctx;
  final bool conquestArmyMovePlannerRan;
  final int conquestPasses;
  final int conquestArmyMoveCount;
}

/// Runs the conquest army-move passes followed by the (optional) relocation
/// army-move pass for one AI-controlled player turn.
///
/// Extracted verbatim from [runDomainPlannersWithOutcome] to keep that
/// orchestrator entrypoint within the repo function-size budget and to mirror
/// the economy/diplomacy/scoring pass-module split delivered for #3749 step 7;
/// behaviour is unchanged.
///
/// The slice owns the contiguous block that previously sat between the
/// declare-war diplomacy pass and the naval gate: it derives the
/// extra-conquest-passes gate from the dispatched [phasePlan], resolves the
/// stalled-conquest declared-war target carried over from
/// [declaredWarTargetFactionId], runs [runConquestArmyMovePlanner] up to
/// [kStalledConquestArmyMovePasses] times (breaking early when a pass emits no
/// new army move), counts the conquest army moves added relative to the
/// pre-pass total, and finally runs the relocation [runArmyMovePlanner] unless
/// the GP is in the stalled extra-passes state (relocation would undo frontier
/// marches). The `aiStageD` progress phase is emitted at the tail exactly as in
/// the inlined version.
_MilitaryDomainPlannersResult _runMilitaryDomainPlanners({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
  required String nationId,
  required String? declaredWarTargetFactionId,
  required void Function(String phaseId) emit,
}) {
  final armyMovesBeforeConquest =
      ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
  // Refs #2509 S5: derive the extra-conquest-passes / relocation-skip
  // gate from the dispatched phase plan instead of recomputing the
  // legacy compound `isStalledOldWorldExpansion(ow) ||
  // isBelowObserverConquestQuota(ow)`. The two `colonizethis_data`
  // predicates are equivalent for integer `ow` (both reduce to
  // `ow <= 9`) and field-equal to `phase ∈ {EXPAND, COLONIAL-lite}`
  // because both phases require `oldWorldProvincesOwned <
  // kObserverConquestMinOwProvincesPerGp` at entry via
  // `observerGoalPhaseFor`. Routing the gate through the dispatched
  // `phasePlan` eliminates two per-player-turn predicate recomputes
  // and preserves the prior extra-passes / relocation-skip behaviour
  // exactly (see `SPEC/ai/phase-planner-dispatch.md` § Orchestrator
  // conquest extra-passes slice).
  final extraPassesActive = resolvePhaseConquestExtraPassesActive(
    phasePlan: phasePlan,
  );
  final conquestDeclaredWarTarget = stalledConquestDeclaredWarTarget(
    game: ctx.game,
    nationId: nationId,
    snapshot: snapshot,
    declaredThisTurn: declaredWarTargetFactionId,
  );
  final conquestPasses = extraPassesActive ? kStalledConquestArmyMovePasses : 1;
  var conquestArmyMovePlannerRan = false;
  for (var pass = 0; pass < conquestPasses; pass++) {
    conquestArmyMovePlannerRan = true;
    final movesBeforePass =
        ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
    ctx = ctx.withOrders(
      runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: conquestDeclaredWarTarget,
        phasePlan: phasePlan,
      ),
    );
    final movesAfterPass =
        ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
    if (movesAfterPass == movesBeforePass) {
      break;
    }
  }
  final conquestArmyMoveCount =
      (ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0) -
      armyMovesBeforeConquest;
  // Stalled GPs must not run the relocation pass: it undoes frontier marches.
  if (!extraPassesActive) {
    ctx = ctx.withOrders(
      runArmyMovePlanner(
        ctx: ctx,
        provincesToVictory: snapshot.conquest.provincesToVictory,
      ),
    );
  }
  emit('aiStageD');
  return _MilitaryDomainPlannersResult(
    ctx: ctx,
    conquestArmyMovePlannerRan: conquestArmyMovePlannerRan,
    conquestPasses: conquestPasses,
    conquestArmyMoveCount: conquestArmyMoveCount,
  );
}
