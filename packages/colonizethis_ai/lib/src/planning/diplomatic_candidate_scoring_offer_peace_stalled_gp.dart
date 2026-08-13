import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart'
    show
        atWarGreatPowerOrderTarget,
        factionOwnsInvadableOldWorldProvince,
        gpFactionIdsAtWarWith,
        isOwnOldWorldExpansionStalled,
        mutualExhaustedGpStalemateSideQualifies;
import 'planning_imports.dart';

/// True when [order] proposes offerPeace toward the sole at-war Great Power and
/// the mutual-exhausted plateau conditions hold for both sides. Mirrors
/// [mutualExhaustedBelowQuotaGpStalematePeaceTargets] inline. Refs #2509.
bool offerPeaceMutualExhaustedBelowQuotaSoleGpStalemate({
  required DiplomaticOrder order,
  required Game game,
  required AIWorldSnapshot snapshot,
  required String nationId,
}) {
  if (!snapshot.threats.atWarWith.contains(order.targetFactionId)) {
    return false;
  }
  final ownOw = snapshot.conquest.oldWorldProvincesOwned;
  // Route the duplicated per-side "mutual-exhausted below-quota GP stalemate"
  // qualification through [mutualExhaustedGpStalemateSideQualifies]
  // (Refs #3717). The inter-side `(enemyOw - ownOw).abs()` proximity gate
  // stays here.
  if (!mutualExhaustedGpStalemateSideQualifies(
    game: game,
    factionId: nationId,
    ow: ownOw,
  )) {
    return false;
  }
  final gpWars = gpFactionIdsAtWarWith(game, snapshot);
  if (gpWars.length != 1 || gpWars.single != order.targetFactionId) {
    return false;
  }
  final enemyOw = provinceCountOwnedBy(game, order.targetFactionId);
  if (!mutualExhaustedGpStalemateSideQualifies(
    game: game,
    factionId: order.targetFactionId,
    ow: enemyOw,
  )) {
    return false;
  }
  if ((enemyOw - ownOw).abs() > 1) {
    return false;
  }
  return true;
}

int offerPeaceStalledGpWarAdjustments({
  required DiplomaticOrder order,
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
  required Player? targetGp,
}) {
  var s = 0;
  // Hoist the repeated "order target is an at-war Great Power" eligibility gate
  // (Refs #3717). Evaluating once is byte-identical to the prior leading
  // conjuncts and avoids redundant `atWarWith.contains` membership tests.
  final atWarGreatPowerTarget = atWarGreatPowerOrderTarget(
    targetGp: targetGp,
    snapshot: snapshot,
    targetFactionId: order.targetFactionId,
  );
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (atWarGreatPowerTarget &&
      !gpBlockerFocus &&
      isOwnOldWorldExpansionStalled(snapshot) &&
      provinceCountOwnedBy(game, order.targetFactionId) >
          snapshot.conquest.oldWorldProvincesOwned &&
      factionOwnsInvadableOldWorldProvince(
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        factionId: order.targetFactionId,
      )) {
    s += kOfferPeaceStalledStrongerGpBlockerBonus;
  }
  if (atWarGreatPowerTarget &&
      isOwnOldWorldExpansionStalled(snapshot) &&
      !factionOwnsInvadableOldWorldProvince(
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        factionId: order.targetFactionId,
      ) &&
      snapshot.conquest.invadableProvinceIdsSorted.any((pid) {
        final owner = provinceOwner[pid];
        return owner != null &&
            (isMinorFaction(game, owner) || game.playerById(owner) != null);
      })) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  final gpBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (atWarGreatPowerTarget &&
      gpBlocker != null &&
      order.targetFactionId != gpBlocker &&
      isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  final gpWarCount = gpFactionIdsAtWarWith(game, snapshot).length;
  if (atWarGreatPowerTarget &&
      gpBlocker != null &&
      gpWarCount > 1 &&
      order.targetFactionId != gpBlocker &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    s += kOfferPeaceStalledFutileGpWarBonus;
  }
  return s;
}
