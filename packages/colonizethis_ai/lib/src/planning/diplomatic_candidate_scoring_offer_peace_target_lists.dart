import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart' show atWarGreatPowerOrderTarget, atWarPeaceTargetBonus;
import 'planning_imports.dart';

int offerPeacePeaceTargetListAdjustments({
  required DiplomaticOrder order,
  required Game game,
  required AIWorldSnapshot snapshot,
  required Player? targetGp,
}) {
  final atWarGp = atWarGreatPowerOrderTarget(
    targetGp: targetGp,
    snapshot: snapshot,
    targetFactionId: order.targetFactionId,
  );
  var s = 0;
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) ==
        order.targetFactionId,
    bonus: kOfferPeaceUnwinnableSoleGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () => stalledBelowQuotaGpLeadPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).contains(order.targetFactionId),
    bonus: kOfferPeaceUnwinnableSoleGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () => belowQuotaPeerGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).contains(order.targetFactionId),
    bonus: kOfferPeaceStalledFutileGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () => nearQuotaHoldPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).contains(order.targetFactionId),
    bonus: kOfferPeaceConsolidateGainsSoleGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () => quotaMetFutileBelowQuotaGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).contains(order.targetFactionId),
    bonus: kOfferPeaceStalledFutileGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () => quotaMetBelowQuotaAtWarPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).contains(order.targetFactionId),
    bonus: kOfferPeaceStalledFutileGpWarBonus,
  );
  s += atWarPeaceTargetBonus(
    atWarGreatPowerTarget: atWarGp,
    isPeaceTarget: () =>
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot) ==
        order.targetFactionId,
    bonus: kOfferPeaceConsolidateGainsSoleGpWarBonus,
  );
  return s;
}
