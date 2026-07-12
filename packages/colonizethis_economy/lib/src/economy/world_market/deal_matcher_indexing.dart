import 'package:colonizethis_models/colonizethis_models.dart';

import 'deal_matcher_session.dart';

/// Order-indexing, aggregation, and carry-forward helpers for the world market
/// deal matcher (Refs #3979). Package-internal library — not barrel-exported.

List<CommodityId> collectMatchCommodityIds(
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

Map<String, List<MatchOrderState>> indexOrdersByFaction(
  Map<String, List<TradeOrder>> ordersByFaction,
) {
  final sortedFactionIds = ordersByFaction.keys.toList()..sort();
  final result = <String, List<MatchOrderState>>{};
  for (final factionId in sortedFactionIds) {
    final orders = ordersByFaction[factionId] ?? const <TradeOrder>[];
    final states = <MatchOrderState>[];
    for (var i = 0; i < orders.length; i++) {
      states.add(
        MatchOrderState(
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

/// Groups every order state by [TradeOrder.commodityId] in a single pass,
/// preserving faction-then-local-index order from [indexOrdersByFaction].
Map<CommodityId, List<MatchOrderState>> indexStatesByCommodity(
  Map<String, List<MatchOrderState>> statesByFaction,
) {
  final out = <CommodityId, List<MatchOrderState>>{};
  for (final entry in statesByFaction.entries) {
    for (final state in entry.value) {
      (out[state.order.commodityId] ??= <MatchOrderState>[]).add(state);
    }
  }
  return out;
}

List<int> collectPriorityTiers(
  List<MatchOrderState> offers,
  List<MatchOrderState> bids,
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

int sumInputQuantity(List<MatchOrderState> states) {
  var total = 0;
  for (final state in states) {
    total += state.order.quantity;
  }
  return total;
}

Map<String, List<TradeOrder>> carryForwardByFaction(
  Map<String, List<MatchOrderState>> statesByFaction,
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
