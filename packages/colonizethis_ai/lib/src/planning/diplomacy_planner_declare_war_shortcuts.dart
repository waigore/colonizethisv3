import '../perception/perception_snapshot.dart';
import '../util/orders_extensions.dart';
import 'diplomacy_planner_declare_war_targets.dart';
import 'diplomacy_planner_result.dart';
import 'expand_peace_frontier_helpers.dart';
import 'phase_planner_declare_war_targets.dart';
import 'phase_planner_dispatch.dart';
import 'planner_context.dart';
import 'planning_imports.dart';

final _log = packageLogger('diplomacy_planner_declare_war_shortcuts');

typedef DeclareWarTargetSelector =
    String? Function({
      required Game game,
      required AIWorldSnapshot snapshot,
    });

typedef DeclareWarShortcutPreGate =
    bool Function({
      required Game game,
      required AIWorldSnapshot snapshot,
    });

final class DeclareWarShortcut {
  const DeclareWarShortcut({
    required this.targetFor,
    required this.logLabel,
    this.preGate,
  });

  final DeclareWarTargetSelector targetFor;
  final String logLabel;
  final DeclareWarShortcutPreGate? preGate;
}

bool plateauGpBlockerDeclarePreGate({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return false;
  }
  if (hasUninvadedOldWorldMinor(
    game: game,
    snapshot: snapshot,
  )) {
    return false;
  }
  return isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
}

const legacyMinorDeclareWarShortcuts = <DeclareWarShortcut>[
  DeclareWarShortcut(
    targetFor: defaultStartOwMinorDeclareTarget,
    logLabel: 'defaultStartMinor',
  ),
  DeclareWarShortcut(
    targetFor: plateauOwMinorDeclareTarget,
    logLabel: 'plateauMinor',
  ),
  DeclareWarShortcut(
    targetFor: belowQuotaUninvadedMinorDeclareTarget,
    logLabel: 'belowQuotaMinor',
  ),
  DeclareWarShortcut(
    targetFor: criticalWeakUninvadedMinorDeclareTarget,
    logLabel: 'target',
  ),
];

const legacyGpBlockerDeclareWarShortcut = DeclareWarShortcut(
  targetFor: stalledGpBlockerDeclareWarTarget,
  logLabel: 'gpBlocker',
  preGate: plateauGpBlockerDeclarePreGate,
);

const legacyStalledGpDeclareWarShortcut = DeclareWarShortcut(
  targetFor: stalledInvadableGpOwnerDeclareTarget,
  logLabel: 'stalledInvadableGp',
);

DiplomacyPlannerResult? legacyDeclareWarShortcutResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required DeclareWarShortcut shortcut,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  if (shortcut.preGate != null &&
      !shortcut.preGate!(
        game: ctx.game,
        snapshot: snapshot,
      )) {
    return null;
  }
  final target = shortcut.targetFor(game: ctx.game, snapshot: snapshot);
  if (target == null) {
    return null;
  }
  return forcedDeclareWarPlannerResult(
    ctx: ctx,
    target: target,
    logLabel: shortcut.logLabel,
  );
}

DiplomacyPlannerResult? forcedDeclareWarPlannerResult({
  required PlannerContext ctx,
  required String target,
  required String logLabel,
}) {
  if (_log.infoEnabled) {
    _log.i(
      'diplomacy forced declareWar nationId=${ctx.nationId} '
      '$logLabel=$target',
    );
  }
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: target,
      ),
    ]),
    declaredWarTargetFactionId: target,
  );
}

/// When [phasePlan] is set, declare-war targets come only from the phase
/// planners via [gpExpandDeclareWarTargetFromPhasePlan] and
/// [gpColonialDeclareWarTargetFromPhasePlan] (Refs #2509 S5).
DiplomacyPlannerResult? phasePlannerDeclareWarPlannerResultIfNeeded({
  required PlannerContext ctx,
  required DiplomacyPlannerPass pass,
  PhasePlanOutcome? phasePlan,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly || phasePlan == null) {
    return null;
  }
  final expandTarget = gpExpandDeclareWarTargetFromPhasePlan(phasePlan);
  if (expandTarget != null) {
    return forcedDeclareWarPlannerResult(
      ctx: ctx,
      target: expandTarget,
      logLabel: 'phaseExpand',
    );
  }
  final colonialTarget = gpColonialDeclareWarTargetFromPhasePlan(phasePlan);
  if (colonialTarget != null) {
    return forcedDeclareWarPlannerResult(
      ctx: ctx,
      target: colonialTarget,
      logLabel: 'phaseColonial',
    );
  }
  return null;
}
