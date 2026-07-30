// Industry Counsel Agree apply handlers. SPEC/ui/counsel-panel.md (Refs #4191).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../widgets/production/production_labour_recruit_economy_mutations.dart';

/// Whether [tier] can still be recruited given current economy and orders.
bool industryCounselTrainTierStillAffordable({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required WorkerTier tier,
}) {
  final view = buildPlayerView(game, topology, playerId);
  final candidates = suggestRecruitWorkerOrders(
    view,
    game,
    topology,
    currentOrders,
  );
  return candidates.any((order) => order.targetTier == tier);
}

/// Appends one recruit order when [tier] is still affordable; otherwise null.
Orders? industryCounselOrdersAfterTrainAgree({
  required Orders currentOrders,
  required String playerId,
  required WorkerTier tier,
  required Game game,
  required MapTopology topology,
}) {
  if (!industryCounselTrainTierStillAffordable(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
    tier: tier,
  )) {
    return null;
  }
  return ordersWithAppendedRecruitWorkerOrder(
    currentOrders: currentOrders,
    playerId: playerId,
    tier: tier,
  );
}

/// Merges the ranker core assignment snapshot into [currentDesired].
Map<String, int> industryCounselDesiredOutputAfterProduceAgree({
  required Game game,
  required String playerId,
  required Map<String, int> currentDesired,
}) {
  final coreSnapshot = industryCounselCoreDesiredOutputByRecipe(
    game: game,
    playerId: playerId,
  );
  return mergeIndustryCounselCoreDesiredOutput(
    currentDesired: currentDesired,
    coreSnapshot: coreSnapshot,
  );
}
