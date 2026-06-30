import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../non_gp_auto_offers.dart';

/// Commodity ids that [buyerPlayerId] cannot source from the World Market
/// because a colony-holding Great Power has an active Boycott against it
/// (Refs #3758 S7/R12; SPEC/ai/treasury-planner.md § Boycott-aware bid
/// suppression).
///
/// For every active `BoycottState { gpId: A, targetGpId: C }` where
/// `C == buyerPlayerId`, every Tribe `T` that is a colony of `A`
/// (`ColonyState.colonyOfGpId == A`) is blocked: all trade between `C` and `T`
/// is refused by the deal matcher (SPEC/program/world-market-resolution.md
/// § Deal matching engine). This helper returns the union of the commodity ids
/// those blocked colony Tribes currently auto-offer, so the AI treasury planner
/// can avoid spending its capped bid slots on commodities it can only buy from
/// a Tribe it is boycotted from.
///
/// Gating (cheap common path): returns the empty set immediately when there is
/// no boycott or colony state, when [tileMapByRegion] is empty, or when
/// [topology] is absent — so the connectivity/auto-offer computation only runs
/// when a boycott actually targets [buyerPlayerId] and tile maps are present.
/// The connectivity/auto-offer computation is itself only reached when at least
/// one colony Tribe is blocked for the buyer. Deterministic for fixed inputs.
Set<CommodityId> boycottedColonySellableCommodityIds({
  required Game game,
  required String buyerPlayerId,
  required Map<String, TileMapResult> tileMapByRegion,
  MapTopology? topology,
}) {
  if (game.boycottStates.isEmpty || game.colonyStates.isEmpty) {
    return const <CommodityId>{};
  }
  if (tileMapByRegion.isEmpty || topology == null) {
    return const <CommodityId>{};
  }

  final blockedTribeIds = <String>{};
  for (final boycott in game.boycottStates) {
    if (boycott.targetGpId != buyerPlayerId) continue;
    for (final colony in game.colonyStates) {
      if (colony.colonyOfGpId == boycott.gpId) {
        blockedTribeIds.add(colony.tribeId);
      }
    }
  }
  if (blockedTribeIds.isEmpty) {
    return const <CommodityId>{};
  }

  final connectivity = resolveNonGreatPowerConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  if (connectivity.isEmpty) {
    return const <CommodityId>{};
  }
  final autoOffers = computeNonGreatPowerAutoOffers(
    game: game,
    tileMapByRegion: tileMapByRegion,
    connectivityByFactionId: connectivity,
  );

  final blocked = <CommodityId>{};
  for (final tribeId in blockedTribeIds) {
    final offers = autoOffers[tribeId];
    if (offers == null) continue;
    for (final offer in offers) {
      blocked.add(offer.commodityId);
    }
  }
  return blocked;
}
