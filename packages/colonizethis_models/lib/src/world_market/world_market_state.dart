part of '../world_market.dart';

/// Aggregate market state stored on `Game` between turns.
///
/// `prices` stores integer per-commodity market prices (post-floor of the
/// price-discovery output). SPEC/game/world-market.md § Price discovery
/// requires the persisted price be floored to the nearest integer; the
/// inner floating-point math in [PriceDiscovery.computeNextPrice] is
/// retained for the supply/demand delta but the world-market phase floors
/// the result before storing it here. Older save files that wrote `double`
/// prices remain loadable: [fromJson] floors any incoming numeric value to
/// the nearest integer so the in-memory map is always int-valued.
class WorldMarketState {
  const WorldMarketState({
    this.prices = const <CommodityId, int>{},
    this.lastTurnActivity = const <CommodityId, MarketActivity>{},
    this.carryForwardOffersByFactionId =
        const <String, List<TradeOrder>>{},
    this.carryForwardBidsByFactionId =
        const <String, List<TradeOrder>>{},
  });

  final Map<CommodityId, int> prices;
  final Map<CommodityId, MarketActivity> lastTurnActivity;

  /// Per-faction unfilled offer carry-forwards from the previous turn's
  /// market phase. Re-entered into matching at the start of the next turn,
  /// subject to stockpile/cargo re-validation per `SPEC/game/world-market.md`
  /// § Order persistence.
  final Map<String, List<TradeOrder>> carryForwardOffersByFactionId;

  /// Per-faction unfilled bid carry-forwards from the previous turn's
  /// market phase. Re-entered into matching at the start of the next turn,
  /// subject to stockpile/cargo re-validation per `SPEC/game/world-market.md`
  /// § Order persistence.
  final Map<String, List<TradeOrder>> carryForwardBidsByFactionId;

  static const empty = WorldMarketState();

  /// Builds an initial state seeded from `defaultMarketPrice` integers
  /// (one entry per non-riches commodity). Activity map starts empty.
  static WorldMarketState withDefaultPrices(Map<CommodityId, int> basePrices) {
    return WorldMarketState(
      prices: Map<CommodityId, int>.unmodifiable(basePrices),
      lastTurnActivity: const <CommodityId, MarketActivity>{},
    );
  }

  WorldMarketState copyWith({
    Map<CommodityId, int>? prices,
    Map<CommodityId, MarketActivity>? lastTurnActivity,
    Map<String, List<TradeOrder>>? carryForwardOffersByFactionId,
    Map<String, List<TradeOrder>>? carryForwardBidsByFactionId,
  }) {
    return WorldMarketState(
      prices: prices ?? this.prices,
      lastTurnActivity: lastTurnActivity ?? this.lastTurnActivity,
      carryForwardOffersByFactionId:
          carryForwardOffersByFactionId ?? this.carryForwardOffersByFactionId,
      carryForwardBidsByFactionId:
          carryForwardBidsByFactionId ?? this.carryForwardBidsByFactionId,
    );
  }

  Map<String, dynamic> toJson() => {
    'prices': prices,
    'lastTurnActivity': {
      for (final entry in lastTurnActivity.entries)
        entry.key: entry.value.toJson(),
    },
    if (carryForwardOffersByFactionId.isNotEmpty)
      'carryForwardOffersByFactionId': _serializeCarryForward(
        carryForwardOffersByFactionId,
      ),
    if (carryForwardBidsByFactionId.isNotEmpty)
      'carryForwardBidsByFactionId': _serializeCarryForward(
        carryForwardBidsByFactionId,
      ),
  };

  static WorldMarketState fromJson(Map<String, dynamic> json) {
    final pricesRaw = json['prices'];
    final prices = <CommodityId, int>{};
    if (pricesRaw is Map<dynamic, dynamic>) {
      pricesRaw.forEach((key, value) {
        final id = key.toString();
        final intValue = _coerceToFlooredInt(value);
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
      carryForwardOffersByFactionId: _deserializeCarryForward(
        json['carryForwardOffersByFactionId'],
      ),
      carryForwardBidsByFactionId: _deserializeCarryForward(
        json['carryForwardBidsByFactionId'],
      ),
    );
  }

  /// Coerces a JSON-decoded price value to a non-negative floored int.
  /// Supports the legacy `double` storage and any string fallback that
  /// stringified the price (defensive; new saves write int directly via
  /// `toJson`). Returns `null` for unparseable values so the caller can
  /// drop the entry entirely.
  static int? _coerceToFlooredInt(Object? value) {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldMarketState &&
          runtimeType == other.runtimeType &&
          _mapEquals(prices, other.prices) &&
          _mapEquals(lastTurnActivity, other.lastTurnActivity) &&
          _carryMapEquals(
            carryForwardOffersByFactionId,
            other.carryForwardOffersByFactionId,
          ) &&
          _carryMapEquals(
            carryForwardBidsByFactionId,
            other.carryForwardBidsByFactionId,
          );

  @override
  int get hashCode {
    final priceEntries = prices.entries
        .map((e) => Object.hash(e.key, e.value))
        .toList(growable: false);
    final activityEntries = lastTurnActivity.entries
        .map((e) => Object.hash(e.key, e.value))
        .toList(growable: false);
    return Object.hash(
      Object.hashAll(priceEntries),
      Object.hashAll(activityEntries),
      Object.hashAll(carryForwardOffersByFactionId.keys),
      Object.hashAll(carryForwardBidsByFactionId.keys),
    );
  }
}

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
          orders.add(
            TradeOrder.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
      if (orders.isNotEmpty) {
        result[key.toString()] = List.unmodifiable(orders);
      }
    }
  });
  return Map.unmodifiable(result);
}
