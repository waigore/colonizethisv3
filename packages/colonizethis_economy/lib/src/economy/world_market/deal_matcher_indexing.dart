part of 'deal_matcher.dart';

// Order-indexing, aggregation, carry-forward, and per-buyer treasury /
// affordability helpers for the world market deal matcher, split out of
// `deal_matcher.dart` by concern to keep each library file below the repo
// non-comment line limit (`SPEC/program/dart-file-non-comment-line-size.md`).
// These are top-level private functions sharing the parent library's scope via
// `part`, so visibility and behaviour are unchanged (Refs #3290 Phase 0).

List<CommodityId> _collectCommodityIds(
  Map<String, List<TradeOrder>> offers,
  Map<String, List<TradeOrder>> bids,
) {
  final set = <CommodityId>{};
  for (final list in offers.values) {
    for (final order in list) {
      set.add(order.commodityId);
    }
  }
  for (final list in bids.values) {
    for (final order in list) {
      set.add(order.commodityId);
    }
  }
  final sorted = set.toList()..sort();
  return sorted;
}

Map<String, List<_OrderState>> _indexOrdersByFaction(
  Map<String, List<TradeOrder>> ordersByFaction,
) {
  final sortedFactionIds = ordersByFaction.keys.toList()..sort();
  final result = <String, List<_OrderState>>{};
  for (final factionId in sortedFactionIds) {
    final orders = ordersByFaction[factionId] ?? const <TradeOrder>[];
    final states = <_OrderState>[];
    for (var i = 0; i < orders.length; i++) {
      states.add(
        _OrderState(
          factionId: factionId,
          order: orders[i],
          factionLocalIndex: i,
        ),
      );
    }
    result[factionId] = states;
  }
  return result;
}

List<_OrderState> _orderedStatesForCommodity(
  Map<String, List<_OrderState>> statesByFaction,
  CommodityId commodityId,
) {
  final out = <_OrderState>[];
  for (final entry in statesByFaction.entries) {
    for (final state in entry.value) {
      if (state.order.commodityId == commodityId) {
        out.add(state);
      }
    }
  }
  return out;
}

List<int> _collectPriorityTiers(
  List<_OrderState> offers,
  List<_OrderState> bids,
) {
  final tiers = <int>{};
  for (final state in offers) {
    tiers.add(state.order.priority);
  }
  for (final state in bids) {
    tiers.add(state.order.priority);
  }
  final sorted = tiers.toList()..sort();
  return sorted;
}

int _sumInputQuantity(List<_OrderState> states) {
  var total = 0;
  for (final state in states) {
    total += state.order.quantity;
  }
  return total;
}

Map<String, List<TradeOrder>> _carryForwardByFaction(
  Map<String, List<_OrderState>> statesByFaction,
) {
  final result = <String, List<TradeOrder>>{};
  for (final entry in statesByFaction.entries) {
    final remaining = <TradeOrder>[];
    for (final state in entry.value) {
      if (state.remaining > 0) {
        remaining.add(state.asCarryForward());
      }
    }
    if (remaining.isNotEmpty) {
      result[entry.key] = List.unmodifiable(remaining);
    }
  }
  return Map.unmodifiable(result);
}

int _min3(int a, int b, int c) {
  var m = a < b ? a : b;
  if (c < m) m = c;
  return m;
}

/// Returns the maximum units the buyer can afford to purchase at
/// [pricePerUnit] given their remaining treasury budget. The
/// `pricePerUnit == 0` branch preserves legacy free-fill behavior on
/// the missing-price defect path per
/// `SPEC/program/world-market-resolution.md` § Step C (Refs #3115):
/// returns a high cap (`bid.remaining`) so the other three clamps
/// dominate.
int _maxAffordableQuantity({
  required _OrderState bid,
  required double pricePerUnit,
  required Map<String, int> remainingTreasury,
}) {
  if (pricePerUnit <= 0.0) return bid.remaining;
  final treasuryLeft = remainingTreasury[bid.factionId] ?? 0;
  if (treasuryLeft <= 0) return 0;
  final affordable = (treasuryLeft / pricePerUnit).floor();
  return affordable < 0 ? 0 : affordable;
}

/// Decrements the per-buyer running treasury tally after a successful
/// match. Skips the decrement on the missing-price defect path so
/// free-fill behavior is preserved (no treasury accounting when no
/// notional is owed).
void _decrementTreasury({
  required _OrderState bid,
  required int matchQty,
  required double pricePerUnit,
  required Map<String, int> remainingTreasury,
}) {
  if (pricePerUnit <= 0.0 || matchQty <= 0) return;
  final notional = (matchQty * pricePerUnit).round();
  final treasuryLeft = remainingTreasury[bid.factionId] ?? 0;
  final next = treasuryLeft - notional;
  remainingTreasury[bid.factionId] = next < 0 ? 0 : next;
}
