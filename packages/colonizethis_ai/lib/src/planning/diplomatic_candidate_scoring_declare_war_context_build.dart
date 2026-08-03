import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'expand_phase_planner.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_diplomacy_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart'
    show
        anyInvadableProvinceOwnedByGreatPower,
        factionOwnsInvadableOldWorldProvince;
import 'planning_imports.dart';

  DeclareWarTargetContext buildDeclareWarTargetContext({
    required DiplomaticOrder order,
    required String nationId,
    required Game game,
    required AIWorldSnapshot snapshot,
    required String agendaId,
    required PersonalityThresholds thresholds,
    required int maxRelationForDeclareWar,
    required bool behindVictoryPace,
    required bool suppressGpDeclareWar,
    required Set<String> invadableOwners,
    required Map<String, String> provinceOwner,
    required int warCooldownTurns,
    required int currentTurn,
    required bool anyMinorOwnsOldWorld,
    required StrategicGoal? primaryGoal,
    required int Function(String targetFactionId, num relationScore)
    warDesireForTarget,
    PhasePlanOutcome? phasePlan,
  }) {
    final relation = snapshot.relations[order.targetFactionId];
    final relationScore = relation?.score ?? 50;
    final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
    final colonialAdjacent =
        snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted;
    final isAdjacentOwner = adjacentOwners.contains(order.targetFactionId);
    final isColonialAdjacentOwner = colonialAdjacent.contains(
      order.targetFactionId,
    );
    final isMinorTarget = isMinorOrTribeFaction(game, order.targetFactionId);
    final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
        .any((pid) => provinceOwner[pid] == order.targetFactionId);
    // Refs #2847 Phase 3 diplomacy wiring: derive the NW acquisition
    // weight from the dispatched phase plan when available, and
    // collapse the legacy COLONIAL-only `colonialPressure` boolean to
    // `nwAcquisitionWeight > 0.0` so the colonial-pressure carve-out
    // in `_declareWarSuppressedWarConcentrationScore` scales continuously
    // with the soft-phase NW priority instead of switching on/off at
    // the EXPAND→COLONIAL boundary
    // (`SPEC/ai/phase-planner-architecture.md` § Soft-phase priority
    // weights). Falls back to the legacy three-predicate compute when no
    // phase plan was threaded through (test paths and other callers);
    // the orchestrator always passes `phasePlan` so production runs
    // route through the weight-derived value. The legacy path retires
    // structurally once every consumer migrates.
    final nwAcquisitionWeight = phasePlan != null
        ? resolvePhaseDiplomacyDeclareWarColonialPressureWeight(
            phasePlan: phasePlan,
          )
        : (hasColonialAcquisitionTargets(snapshot.colonial) &&
                  !isStalledOldWorldGpBlockerFocus(
                    game: game,
                    snapshot: snapshot,
                  ) &&
                  !shouldSuppressNewWorldColonialOrders(
                    snapshot: snapshot,
                    game: game,
                  )
              ? 1.0
              : 0.0);
    final colonialPressure = nwAcquisitionWeight > 0.0;
    final oldWorldConquestWeight = phasePlan != null
        ? resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight(
            phasePlan: phasePlan,
          )
        : 1.0;
    final isTribeTarget = isTribeFaction(game, order.targetFactionId);
    final stalledOwExpansion = isObserverConquestExpansionPressure(
      snapshot.conquest.oldWorldProvincesOwned,
    );
    final ownsInvadableOwMinor =
        isMinorTarget &&
        !isTribeTarget &&
        invadableOwners.contains(order.targetFactionId);
    final minorProvinces = isMinorTarget && !isTribeTarget
        ? provinceCountOwnedBy(game, order.targetFactionId)
        : 0;
    final weakerDistantMinor =
        stalledOwExpansion &&
        behindVictoryPace &&
        isMinorTarget &&
        !isTribeTarget &&
        !isAdjacentOwner &&
        !invadableOwners.contains(order.targetFactionId) &&
        !isColonialAdjacentOwner &&
        !ownsInvadableNw &&
        minorProvinces > 0 &&
        minorProvinces < snapshot.conquest.oldWorldProvincesOwned;
    final hasInvadableMinorOwner = invadableOwners.any(
      (id) => isMinorFaction(game, id),
    );
    final ownerCache = ProvinceOwnerCache.of(game.worldState);
    final minorsHoldOldWorldProvinces = game.minorNations.any(
      (m) => ownerCache.ownsAnyInRegion(m.id, kRegionOldWorld),
    );
    final atWarInvadableOwMinor = snapshot.threats.atWarWith.any(
      (factionId) =>
          isMinorFaction(game, factionId) &&
          invadableOwners.contains(factionId),
    );
    final activeMinorConflicts = activeOldWorldMinorConflictIds(
      game: game,
      nationId: nationId,
      currentTurn: currentTurn,
      warCooldownTurns: warCooldownTurns,
    );
    final hasAdjacentInvadableMinorOwner = adjacentOwners.any(
      (id) =>
          isMinorFaction(game, id) &&
          invadableOwners.contains(id),
    );
    final isAdjacentGp =
        isAdjacentOwner && game.playerById(order.targetFactionId) != null;
    final invadableGpBlocker =
        game.playerById(order.targetFactionId) != null &&
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: provinceOwner,
          factionId: order.targetFactionId,
        );
    final invadableGpBlockerWeaker =
        invadableGpBlocker &&
        provinceCountOwnedBy(game, order.targetFactionId) <=
            snapshot.conquest.oldWorldProvincesOwned;
    final invadableOwOwnedByGp = anyInvadableProvinceOwnedByGreatPower(
      game: game,
      snapshot: snapshot,
      provinceOwner: provinceOwner,
    );
    final tribeOwnsOwInvadable =
        isTribeTarget &&
        factionOwnsInvadableOldWorldProvince(
          snapshot: snapshot,
          provinceOwner: provinceOwner,
          factionId: order.targetFactionId,
        );
    return DeclareWarTargetContext(
      order: order,
      nationId: nationId,
      game: game,
      snapshot: snapshot,
      agendaId: agendaId,
      thresholds: thresholds,
      maxRelationForDeclareWar: maxRelationForDeclareWar,
      behindVictoryPace: behindVictoryPace,
      suppressGpDeclareWar: suppressGpDeclareWar,
      invadableOwners: invadableOwners,
      provinceOwner: provinceOwner,
      warCooldownTurns: warCooldownTurns,
      currentTurn: currentTurn,
      anyMinorOwnsOldWorld: anyMinorOwnsOldWorld,
      primaryGoal: primaryGoal,
      warDesireForTarget: warDesireForTarget,
      relation: relation,
      relationScore: relationScore,
      adjacentOwners: adjacentOwners,
      isAdjacentOwner: isAdjacentOwner,
      isColonialAdjacentOwner: isColonialAdjacentOwner,
      isMinorTarget: isMinorTarget,
      ownsInvadableNw: ownsInvadableNw,
      colonialPressure: colonialPressure,
      nwAcquisitionWeight: nwAcquisitionWeight,
      oldWorldConquestWeight: oldWorldConquestWeight,
      isTribeTarget: isTribeTarget,
      stalledOwExpansion: stalledOwExpansion,
      ownsInvadableOwMinor: ownsInvadableOwMinor,
      weakerDistantMinor: weakerDistantMinor,
      hasInvadableMinorOwner: hasInvadableMinorOwner,
      minorsHoldOldWorldProvinces: minorsHoldOldWorldProvinces,
      atWarInvadableOwMinor: atWarInvadableOwMinor,
      activeMinorConflicts: activeMinorConflicts,
      hasAdjacentInvadableMinorOwner: hasAdjacentInvadableMinorOwner,
      isAdjacentGp: isAdjacentGp,
      invadableGpBlocker: invadableGpBlocker,
      invadableGpBlockerWeaker: invadableGpBlockerWeaker,
      invadableOwOwnedByGp: invadableOwOwnedByGp,
      tribeOwnsOwInvadable: tribeOwnsOwInvadable,
      phasePlan: phasePlan,
    );
}
