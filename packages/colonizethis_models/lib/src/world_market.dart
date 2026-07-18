import 'model_collection_equality.dart';
import 'model_validation_exception.dart';
import 'stockpile.dart';

part 'world_market/trade_order.dart';
part 'world_market/market_activity.dart';
part 'world_market/world_market_state.dart';
part 'world_market/deal_matching.dart';

/// World market data types for the per-turn commodity trading system.
///
/// SPEC/game/world-market.md, SPEC/program/world-market-resolution.md.
///
/// These are pure value types: immutable, JSON-serializable, value-equal.
/// They have no behavior beyond construction, equality, and serialization.
/// Resolution algorithms live in `colonizethis_logic` (matching engine,
/// price discovery), and order plumbing lives on `Orders.tradeOrders`.
///
/// Concrete types are split across `world_market/` part files by concern:
/// `trade_order.dart` (order intent), `market_activity.dart` (per-commodity
/// activity + notes), `world_market_state.dart` (persisted aggregate), and
/// `deal_matching.dart` (matcher output). Collection equality uses
/// [model_collection_equality] (Refs #4068).
