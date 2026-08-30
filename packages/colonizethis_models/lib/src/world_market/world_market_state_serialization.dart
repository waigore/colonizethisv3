/// [WorldMarketState] JSON encode/decode helpers extracted so the aggregate
/// stays under the models physical-line cap (Refs #4334 wave 3). Public API
/// remains [WorldMarketState.toJson] / [WorldMarketState.fromJson].
library;

import '../stockpile.dart';
import 'market_activity.dart';
import 'overseas_profit_credit_record.dart';
import 'trade_order.dart';
import 'world_market_state.dart';

Map<String, dynamic> encodeWorldMarketStateToJson(WorldMarketState state) => {
  'prices': state.prices,
  'lastTurnActivity': {
    for (final entry in state.lastTurnActivity.entries)
      entry.key: entry.value.toJson(),
  },
  if (state.carryForwardOffersByFactionId.isNotEmpty)
    'carryForwardOffersByFactionId': serializeWorldMarketCarryForward(
      state.carryForwardOffersByFactionId,
    ),
  if (state.carryForwardBidsByFactionId.isNotEmpty)
    'carryForwardBidsByFactionId': serializeWorldMarketCarryForward(
      state.carryForwardBidsByFactionId,
    ),
  if (state.completedTradePairKeys.isNotEmpty)
    'completedTradePairKeys': state.completedTradePairKeys.toList(),
  if (state.lastTurnOverseasProfitCreditsByGpId.isNotEmpty)
    'lastTurnOverseasProfitCreditsByGpId': serializeOverseasProfitCredits(
      state.lastTurnOverseasProfitCreditsByGpId,
    ),
};

WorldMarketState decodeWorldMarketStateFromJson(Map<String, dynamic> json) {
  final pricesRaw = json['prices'];
  final prices = <CommodityId, int>{};
  if (pricesRaw is Map<dynamic, dynamic>) {
    pricesRaw.forEach((key, value) {
      final id = key.toString();
      final intValue = coerceWorldMarketPriceToFlooredInt(value);
      if (intValue == null) return;
      prices[id] = intValue;
    });
  }
  final actRaw = json['lastTurnActivity'];
  final activity = <CommodityId, MarketActivity>{};
  if (actRaw is Map<dynamic, dynamic>) {
    actRaw.forEach((key, value) {
      if (value is Map<dynamic, dynamic>) {
        activity[key.toString()] = MarketActivity.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });
  }
  return WorldMarketState(
    prices: Map.unmodifiable(prices),
    lastTurnActivity: Map.unmodifiable(activity),
    carryForwardOffersByFactionId: deserializeWorldMarketCarryForward(
      json['carryForwardOffersByFactionId'],
    ),
    carryForwardBidsByFactionId: deserializeWorldMarketCarryForward(
      json['carryForwardBidsByFactionId'],
    ),
    completedTradePairKeys: deserializeCompletedTradePairKeys(
      json['completedTradePairKeys'],
    ),
    lastTurnOverseasProfitCreditsByGpId: deserializeOverseasProfitCredits(
      json['lastTurnOverseasProfitCreditsByGpId'],
    ),
  );
}

/// Coerces a JSON-decoded price value to a non-negative floored int.
/// Supports the legacy `double` storage and any string fallback that
/// stringified the price (defensive; new saves write int directly via
/// `toJson`). Returns `null` for unparseable values so the caller can
/// drop the entry entirely.
int? coerceWorldMarketPriceToFlooredInt(Object? value) {
  if (value is int) {
    return value < 0 ? 0 : value;
  }
  if (value is num) {
    final floored = value.floor();
    return floored < 0 ? 0 : floored;
  }
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) return null;
  final floored = parsed.floor();
  return floored < 0 ? 0 : floored;
}

Map<String, List<Map<String, dynamic>>> serializeOverseasProfitCredits(
  Map<String, List<OverseasProfitCreditRecord>> map,
) {
  final result = <String, List<Map<String, dynamic>>>{};
  for (final entry in map.entries) {
    result[entry.key] = entry.value.map((r) => r.toJson()).toList();
  }
  return result;
}

Map<String, List<OverseasProfitCreditRecord>> deserializeOverseasProfitCredits(
  Object? raw,
) {
  if (raw is! Map<dynamic, dynamic>) {
    return const <String, List<OverseasProfitCreditRecord>>{};
  }
  final result = <String, List<OverseasProfitCreditRecord>>{};
  raw.forEach((key, value) {
    if (value is List<dynamic>) {
      final records = <OverseasProfitCreditRecord>[];
      for (final entry in value) {
        if (entry is Map<dynamic, dynamic>) {
          records.add(
            OverseasProfitCreditRecord.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          );
        }
      }
      if (records.isNotEmpty) {
        result[key.toString()] = List<OverseasProfitCreditRecord>.unmodifiable(
          records,
        );
      }
    }
  });
  return Map.unmodifiable(result);
}

Set<String> deserializeCompletedTradePairKeys(Object? raw) {
  if (raw is! List<dynamic>) return const <String>{};
  final result = <String>{};
  for (final entry in raw) {
    final key = entry?.toString();
    if (key != null && key.isNotEmpty) result.add(key);
  }
  return Set<String>.unmodifiable(result);
}

Map<String, List<Map<String, dynamic>>> serializeWorldMarketCarryForward(
  Map<String, List<TradeOrder>> map,
) {
  final result = <String, List<Map<String, dynamic>>>{};
  for (final entry in map.entries) {
    result[entry.key] = entry.value.map((o) => o.toJson()).toList();
  }
  return result;
}

Map<String, List<TradeOrder>> deserializeWorldMarketCarryForward(Object? raw) {
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
