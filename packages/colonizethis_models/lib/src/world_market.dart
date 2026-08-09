/// World market data types for the per-turn commodity trading system.
///
/// SPEC/game/world-market.md, SPEC/program/world-market-resolution.md.
///
/// These are pure value types: immutable, JSON-serializable, value-equal.
/// They have no behavior beyond construction, equality, and serialization.
/// Resolution algorithms live in `colonizethis_logic` (matching engine,
/// price discovery), and order plumbing lives on `Orders.tradeOrders`.
///
/// Concrete types live under `world_market/` as first-class libraries
/// (Refs #4068 Slice C). Collection equality uses [model_collection_equality].

export 'world_market/deal_matching.dart';
export 'world_market/filled_deal.dart';
export 'world_market/market_activity.dart';
export 'world_market/overseas_profit_credit_record.dart';
export 'world_market/trade_order.dart';
export 'world_market/world_market_state.dart';
