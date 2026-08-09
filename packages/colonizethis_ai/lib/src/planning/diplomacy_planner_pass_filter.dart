import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'planner_context.dart';
import 'planning_helpers.dart'
    show
        anyInvadableProvinceOwnedByMinor,
        gpFactionIdsAtWarWith,
        isAtWarWithAnyGreatPower;
import 'planning_imports.dart';
import 'diplomacy_planner_result.dart' show DiplomacyPlannerPass;

List<DiplomaticOrder> filterDiplomacyCandidatesForPass({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required List<DiplomaticOrder> candidates,
}) {
  var filtered = candidates;
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final atWarWithGp = isAtWarWithAnyGreatPower(ctx.game, snapshot);
    if (atWarWithGp) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                !isTribeFaction(ctx.game, o.targetFactionId),
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    final provinceOwner = getProvinceOwnerMap(ctx.game);
    final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
      game: ctx.game,
      snapshot: snapshot,
      provinceOwner: provinceOwner,
    );
    if (minorsOwnInvadable) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                !isTribeFaction(ctx.game, o.targetFactionId),
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final gpWars = gpFactionIdsAtWarWith(ctx.game, snapshot);
    final blocker = primaryInvadableOldWorldGpBlocker(
      game: ctx.game,
      snapshot: snapshot,
    );
    final consolidateGpFronts =
        gpWars.length > 1 ||
        (isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
            gpWars.isNotEmpty);
    final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
      game: ctx.game,
      snapshot: snapshot,
    );
    if (blocker != null && gpOnlyFrontier) {
      final mutualPlateauBlocker = isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(ctx.game, blocker),
      );
      if (!mutualPlateauBlocker) {
        filtered = filtered
            .where(
              (o) =>
                  o.type != DiplomaticOrderType.declareWar ||
                  o.targetFactionId == blocker,
            )
            .toList();
      }
    } else if (blocker != null && consolidateGpFronts) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                ctx.game.playerById(o.targetFactionId) == null ||
                o.targetFactionId == blocker,
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.nonDeclareWarOnly &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
    final blocker = primaryInvadableOldWorldGpBlocker(
      game: ctx.game,
      snapshot: snapshot,
    );
    final allowBlockerPeace =
        blocker != null &&
        unwinnableSoleGpFrontierPeaceTarget(
              game: ctx.game,
              snapshot: snapshot,
            ) ==
            blocker;
    filtered = filtered
        .where(
          (o) =>
              o.type != DiplomaticOrderType.alliance &&
              !(o.type == DiplomaticOrderType.offerPeace &&
                  o.targetFactionId == blocker &&
                  !allowBlockerPeace),
        )
        .toList();
  }
  final existingThisTurn =
      ctx.orders.diplomaticOrdersByPlayerId[ctx.nationId] ?? const [];
  final declaredThisTurn = <String>{
    for (final o in existingThisTurn)
      if (o.type == DiplomaticOrderType.declareWar) o.targetFactionId,
  };
  switch (pass) {
    case DiplomacyPlannerPass.declareWarOnly:
    case DiplomacyPlannerPass.all:
      return filtered;
    case DiplomacyPlannerPass.nonDeclareWarOnly:
      return filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar &&
                !declaredThisTurn.contains(o.targetFactionId) &&
                !existingThisTurn.any(
                  (existing) =>
                      existing.type == o.type &&
                      existing.targetFactionId == o.targetFactionId,
                ),
          )
          .toList();
  }
}

