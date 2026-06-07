/// World-market bid-type cap helpers.
///
/// These are **pure** world-market economy helpers (deterministic for fixed
/// inputs, silent — no logger calls) used by trade-order validation,
/// suggestion, and AI bid planning. They depend only on `colonizethis_models`,
/// `colonizethis_data`, and the `colonizethis_logic` core `GamePlayerLookup`
/// extension, so they carry no dependency on the diplomacy domain (Refs #3290
/// — break the economy -> diplomacy import edge; the helpers were previously
/// co-located in `diplomacy_subsidies_relations_resolver.dart`).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart' show GamePlayerLookup;

/// Baseline distinct-commodity bid cap for a known player with no embassy.
///
/// Authorizes basic participation in the single global world market for every
/// Great Power, including EXPAND-phase GPs that are structurally blocked from
/// emitting `establishOverture` orders. Refs #2924; SPEC/game/world-market.md
/// § Bid type cap and SPEC/program/world-market-resolution.md § Bid type cap
/// helper.
const int kWorldMarketBaselineBidTypeCap = 1;

/// World-market bid-type cap (distinct bid commodities per turn).
///
/// Semantics aggregate across **all** of the player's embassies because the
/// market is global, not per-target. Returns:
///
/// - [kWorldMarketBaselineBidTypeCap] (1) when the player has no embassy-tier
///   overture ([OvertureState.hasEmbassy]) with any target.
/// - `3` when the player has at least one embassy-tier overture and has not
///   unlocked [kTechIdTradeFairs].
/// - `6` when the player has at least one embassy-tier overture and has
///   unlocked [kTechIdTradeFairs].
///
/// Source of truth: SPEC/program/world-market-resolution.md § Bid type cap
/// helper. Per-target trade-agreement slots remain governed by `tradeSlotsForGp`
/// in `diplomacy_subsidies_relations_resolver.dart`. Refs #2989 A5.
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
