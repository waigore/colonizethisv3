import '../perception/perception_snapshot.dart';
import 'expand_phase_planner_economy.dart' show ExpandEconomyPlan;
import 'phase_priority_weights.dart' show isNwLockRecoveryPathEActive;
import 'planning_imports.dart';
import 'colonial_phase_planner_acquisition_helpers.dart';
import 'colonial_phase_planner_acquisition_types.dart';

export 'colonial_phase_planner_acquisition_helpers.dart'
    show AcquisitionSearchContext;
export 'colonial_phase_planner_acquisition_types.dart';

/// COLONIAL acquisition target for this turn, or `null` when none is achievable.
///
/// Contract: `SPEC/ai/phase-planner-architecture.md` (adjacency-distance
/// iteration, personality bias, own-colony exclusion, overseas-profit
/// purchase-land) and issue #2509 § planColonialAcquisition. Join Empire
/// gates on [OvertureStage.nap] to match the order-engine validator.
/// Declare-war is last-resort on every turn (issue #2509's turn-110
/// inversion is a no-op).
ColonialAcquisitionTarget? planColonialAcquisition({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? personalityId,
  ExpandEconomyPlan expandEconomyPlan = ExpandEconomyPlan.defaultPlan,
}) {
  if (game.playerById(snapshot.playerId) == null) {
    return null;
  }
  final invadable = acquisitionIterationOrder(snapshot.colonial);
  if (invadable.isEmpty) {
    return null;
  }

  final provinceOwner = getProvinceOwnerMap(game);
  final treasury = snapshot.economy.treasury;
  // Own-colony exclusion (Refs #3758 R4 / S3; SPEC/ai/phase-planner-architecture.md
  // § Own-colony exclusion): tribes that are already this player's colony stay
  // in the game and keep owning NW provinces, so they remain in the invadable
  // list. Skip them across every acquisition arm so the planner never
  // re-targets, re-buys land in, or declares war on its own colony.
  final ownColonyTribeIds = acquisitionOwnColonyTribeIds(
    game,
    snapshot.playerId,
  );
  final preferDeclareWarOverJoinEmpire =
      acquisitionPersonalityPrefersWarOverAlliance(personalityId);
  final searchContext = AcquisitionSearchContext(
    game: game,
    snapshot: snapshot,
    invadable: invadable,
    provinceOwner: provinceOwner,
    treasury: treasury,
    ownColonyTribeIds: ownColonyTribeIds,
  );

  ColonialAcquisitionTarget? tryJoinEmpire() =>
      acquisitionFindJoinEmpireTarget(searchContext);
  ColonialAcquisitionTarget? tryPurchaseLand() =>
      acquisitionFindPurchaseLandTarget(searchContext);
  final waiveDeclareWarTreasuryGate = isNwLockRecoveryPathEActive(
    snapshot: snapshot,
    expandEconomyPlan: expandEconomyPlan,
  );
  ColonialAcquisitionTarget? tryDeclareWar() => acquisitionFindDeclareWarTarget(
    searchContext,
    waiveTreasuryGate: waiveDeclareWarTreasuryGate,
  );

  if (preferDeclareWarOverJoinEmpire) {
    return tryDeclareWar() ?? tryJoinEmpire() ?? tryPurchaseLand();
  }
  return tryJoinEmpire() ?? tryPurchaseLand() ?? tryDeclareWar();
}
