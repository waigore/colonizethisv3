/// Available-treasury **budget projection** for world-market bids
/// (Refs #3093, #4049 phase-7 split).
///
/// SPEC/game/world-market.md § Treasury budget for bids,
/// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.
///
/// Pure and silent like its siblings `treasury_bid_spend.dart` and
/// `treasury_bid_caps.dart`; callers import the `treasury_bid_budget.dart`
/// barrel. Validator-side enforcement lives in `trade_order_validator.dart`
/// (rule 5).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup;

/// Treasury budget [playerId] may commit to bids this turn.
///
/// Returns `max(0, treasury − pendingNonBidDeficit)`, where
/// `pendingNonBidDeficit = max(0, −projectedNonBidTreasuryDelta)`. The
/// helper therefore stays **conservative**:
///
/// * A negative `projectedNonBidTreasuryDelta` (the player's non-bid
///   staged orders — build / recruit / civilian work / subsidies — would
///   net-debit treasury this turn) reduces the bid budget by exactly
///   that deficit.
/// * A non-negative `projectedNonBidTreasuryDelta` (net income or
///   neutral) leaves the bid budget at the raw `treasury` value; net
///   non-bid income never raises the budget so the clamp never lets the
///   player commit treasury they only project to earn.
///
/// `projectedNonBidTreasuryDelta` defaults to `0`, which preserves the
/// legacy "raw treasury" contract for callers that do not run a
/// projection (e.g. Widgetbook stories, isolated widget tests, and AI
/// suggestion paths that have not yet wired projection).
///
/// Callers (UI + validator) factor in the player's own staged **other**
/// bid spend by composing this helper with `stagedBidTotalSpendByPlayer`,
/// so the effective treasury budget for the row currently being clamped
/// is:
///
///     treasuryAvailableForBidsByPlayer(...) - (
///        stagedBidTotalSpendByPlayer(...) - rowPriorBidSpend
///     )
///
/// The Trade Screen Market tab computes
/// `projectedNonBidTreasuryDelta` as
/// `treasurySummaryProvider.projectedDelta + stagedBidTotalSpendByPlayer(...)`
/// (`projectedDelta` is the signed `projectOrderEffects(orders)` net
/// treasury change including bids; adding the player's running bid spend
/// back reconstructs the non-bid contribution) per
/// `SPEC/ui/trade-screen.md` § Market tab — treasury bid cap. When the
/// projection is unavailable
/// (`treasurySummaryProvider.projectedDelta == null`) the UI passes `0`
/// and the helper falls back to raw treasury.
///
/// Returns `0` when [playerId] does not resolve to a player.
int treasuryAvailableForBidsByPlayer({
  required Game game,
  required String playerId,
  int projectedNonBidTreasuryDelta = 0,
}) {
  final player = game.playerById(playerId);
  if (player == null) return 0;
  final int treasury = player.treasury;
  if (treasury <= 0) return 0;
  final int pendingDeficit = projectedNonBidTreasuryDelta < 0
      ? -projectedNonBidTreasuryDelta
      : 0;
  final int budget = treasury - pendingDeficit;
  return budget < 0 ? 0 : budget;
}
