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
/// `deal_matching.dart` (matcher output). The shared value-equality helpers
/// below stay in this host library so every part can reuse them.

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _carryMapEquals(
  Map<String, List<TradeOrder>> a,
  Map<String, List<TradeOrder>> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null) return false;
    if (!_listEquals(entry.value, other)) return false;
  }
  return true;
}
