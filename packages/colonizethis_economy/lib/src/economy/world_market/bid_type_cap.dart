/// World-market bid-type cap helpers.
///
/// These are **pure** world-market economy helpers (deterministic for fixed
/// inputs, silent — no logger calls) used by trade-order validation,
/// suggestion, and AI bid planning. They depend only on `colonizethis_models`,
/// `colonizethis_data`, and the `colonizethis_world` `GamePlayerLookup`
/// extension, so they carry no dependency on the diplomacy domain (Refs #3290
/// — break the economy -> diplomacy import edge; the helpers were previously
/// co-located in `diplomacy_subsidies_relations_resolver.dart`).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup;

/// Baseline distinct-commodity bid cap for a known Great Power without
/// [kTechIdTradeFairs].
///
/// Authorizes participation in the single global world market for every Great
/// Power, including EXPAND-phase GPs that are structurally blocked from
/// emitting `establishOverture` orders. Refs #2924, #4186;
/// SPEC/game/world-market.md § Bid type cap and
/// SPEC/program/world-market-resolution.md § Bid type cap helper.
const int kWorldMarketBaselineBidTypeCap = 3;

/// World-market bid-type cap (distinct bid commodities per turn).
///
/// Embassy presence does **not** affect this cap (Refs #4186). Returns:
///
/// - [kWorldMarketBaselineBidTypeCap] (3) when the player exists and has not
///   unlocked [kTechIdTradeFairs].
/// - `6` when the player has unlocked [kTechIdTradeFairs].
///
/// Source of truth: SPEC/program/world-market-resolution.md § Bid type cap
/// helper. Per-target trade-agreement slots remain governed by `tradeSlotsForGp`
/// in `diplomacy_subsidies_relations_resolver.dart`. Refs #2989 A5.
int worldMarketBidTypeCap(Game game, String playerId) {
  final p = game.playerById(playerId);
  if (p == null) return 0;
  final u = p.techUnlocked ?? const <String, bool>{};
  return u[kTechIdTradeFairs] == true ? 6 : kWorldMarketBaselineBidTypeCap;
}
