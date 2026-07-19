import '../perception/perception_snapshot.dart';
import 'diplomacy_planner.dart';
import 'phase_planner_dispatch.dart';
import 'planner_context.dart';

/// Pre-conquest diplomacy slice carrying the post-pass [PlannerContext] and the
/// declare-war target (if any) the military pass needs to thread into conquest
/// planning (Refs #2509).
class PreConquestDiplomacyResult {
  const PreConquestDiplomacyResult({
    required this.ctx,
    required this.declaredWarTargetFactionId,
  });

  final PlannerContext ctx;
  final String? declaredWarTargetFactionId;
}

/// Runs the two pre-conquest diplomacy passes — peace-before-conquest
/// ([DiplomacyPlannerPass.nonDeclareWarOnly]) followed by declare-war
/// ([DiplomacyPlannerPass.declareWarOnly]) — applying each pass's orders into
/// [ctx] and surfacing the resolved declare-war target for the downstream
/// military pass.
///
/// Extracted verbatim from [runDomainPlannersWithOutcome] to keep that
/// orchestrator within the repo function-size budget and to mirror the
/// economy/military pass modules; behaviour and pass ordering are unchanged.
PreConquestDiplomacyResult runPreConquestDiplomacyPlanners({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
}) {
  final peaceBeforeConquestResult = runDiplomacyPlannerWithResult(
    ctx: ctx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.nonDeclareWarOnly,
    phasePlan: phasePlan,
  );
  var nextCtx = ctx.withOrders(peaceBeforeConquestResult.orders);

  final declareWarResult = runDiplomacyPlannerWithResult(
    ctx: nextCtx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.declareWarOnly,
    phasePlan: phasePlan,
  );
  nextCtx = nextCtx.withOrders(declareWarResult.orders);

  return PreConquestDiplomacyResult(
    ctx: nextCtx,
    declaredWarTargetFactionId: declareWarResult.declaredWarTargetFactionId,
  );
}

/// Runs the late peace pass ([DiplomacyPlannerPass.nonDeclareWarOnly]) that
/// undoes a same-turn declare-war on the OW frontier blocker (observer seed-42
/// gp5/gp6; Refs #2509), returning [ctx] with the pass orders applied.
///
/// Extracted verbatim from [runDomainPlannersWithOutcome]; behaviour is
/// unchanged.
PlannerContext runLatePeaceDiplomacyPlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
}) {
  return ctx.withOrders(
    runDiplomacyPlannerWithResult(
      ctx: ctx,
      snapshot: snapshot,
      pass: DiplomacyPlannerPass.nonDeclareWarOnly,
      phasePlan: phasePlan,
    ).orders,
  );
}
