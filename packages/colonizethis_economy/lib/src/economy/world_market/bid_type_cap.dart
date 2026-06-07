/// World-market bid type cap helper. SPEC/game/world-market.md § Bid type cap.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup;

/// Baseline distinct-commodity bid cap for a known player with no embassy.
///
/// Authorizes basic participation in the single global world market for every
/// Great Power, including EXPAND-phase GPs that are structurally blocked from
/// emitting `establishOverture` orders. Refs #2924; SPEC/game/world-market.md
/// § Bid type cap and SPEC/program/world-market-resolution.md § Bid type cap
/// helper.
const int kWorldMarketBaselineBidTypeCap = 1;

int worldMarketBidTypeCap(Game game, String playerId) {
  final p = game.playerById(playerId);
  if (p == null) return 0;
  final hasAnyEmbassy = game.overtureStates.any(
    (o) => o.gpId == playerId && o.hasEmbassy,
  );
  if (!hasAnyEmbassy) return kWorldMarketBaselineBidTypeCap;
  final u = p.techUnlocked ?? const <String, bool>{};
  return u[kTechIdTradeFairs] == true ? 6 : 3;
}
