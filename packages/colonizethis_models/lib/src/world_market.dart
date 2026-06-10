/// World market data types for the per-turn commodity trading system.
///
/// SPEC/game/world-market.md, SPEC/program/world-market-resolution.md.
///
/// These are pure value types: immutable, JSON-serializable, value-equal.
/// They have no behavior beyond construction, equality, and serialization.
/// Resolution algorithms live in `colonizethis_logic` (matching engine,
/// price discovery), and order plumbing lives on `Orders.tradeOrders`.
///
/// Split by concern (Refs #3393 Phase 5b): order types, market activity,
/// aggregate market state, and deal-matching results each live in a `part`
/// under `world_market/`. Parts share the library-private value-equality
/// helpers declared below. Importers of `src/world_market.dart` and the
/// public `colonizethis_models` barrel are unaffected.
library;

import 'model_validation_exception.dart';
import 'stockpile.dart';

part 'world_market/deal_match.dart';
part 'world_market/market_activity.dart';
part 'world_market/trade_order.dart';
part 'world_market/world_market_state.dart';

const Object _copyWithUnset = Object();

Map<String, List<Map<String, dynamic>>> _serializeCarryForward(
  Map<String, List<TradeOrder>> map,
) {
  final result = <String, List<Map<String, dynamic>>>{};
  for (final entry in map.entries) {
    result[entry.key] = entry.value.map((o) => o.toJson()).toList();
  }
  return result;
}

Map<String, List<TradeOrder>> _deserializeCarryForward(Object? raw) {
  if (raw is! Map<dynamic, dynamic>) {
    return const <String, List<TradeOrder>>{};
  }
  final result = <String, List<TradeOrder>>{};
  raw.forEach((key, value) {
    if (value is List<dynamic>) {
      final orders = <TradeOrder>[];
      for (final entry in value) {
        if (entry is Map<dynamic, dynamic>) {
          orders.add(TradeOrder.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
      if (orders.isNotEmpty) {
        result[key.toString()] = List.unmodifiable(orders);
      }
    }
  });
  return Map.unmodifiable(result);
}

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
