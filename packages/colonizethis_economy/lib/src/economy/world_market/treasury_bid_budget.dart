/// Treasury budget surface for the world-market bid clamp on the Trade
/// Screen Market tab (Refs #3093; phase-7 split Refs #4049).
///
/// SPEC/game/world-market.md § Treasury budget for bids,
/// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.
///
/// Barrel over the three single-concern sibling libraries so every
/// existing call site (validator, suggester, deal-matcher session, UI,
/// AI planners) keeps one stable import:
///
/// * `treasury_bid_spend.dart` — effective price lookup and per-order /
///   staged / carry-forward bid **spend** totals.
/// * `treasury_bid_available.dart` — the player's **available** bid
///   budget with the projected non-bid deficit subtracted.
/// * `treasury_bid_caps.dart` — bid quantity **caps** and the
///   fill-time treasury **decrement** shared by matcher, suggester,
///   and validator.
///
/// Validator-side enforcement lives in `trade_order_validator.dart`
/// (rule 5).
library;

export 'treasury_bid_available.dart';
export 'treasury_bid_caps.dart';
export 'treasury_bid_spend.dart';
