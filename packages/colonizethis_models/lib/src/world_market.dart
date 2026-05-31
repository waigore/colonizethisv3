import 'model_validation_exception.dart';
import 'stockpile.dart';

/// World market data types for the per-turn commodity trading system.
///
/// SPEC/game/world-market.md, SPEC/program/world-market-resolution.md.
///
/// These are pure value types: immutable, JSON-serializable, value-equal.
/// They have no behavior beyond construction, equality, and serialization.
/// Resolution algorithms live in `colonizethis_logic` (matching engine,
/// price discovery), and order plumbing lives on `Orders.tradeOrders`.

/// Buy or sell intent for a [TradeOrder].
enum TradeOrderType {
  bid,
  offer;

  String toJsonName() => name;

  static TradeOrderType fromJsonName(String value) {
    for (final t in TradeOrderType.values) {
      if (t.name == value) return t;
    }
    throw ModelValidationException.value(
      value,
      'value',
      'unknown TradeOrderType',
    );
  }
}

/// Outcome status for a [TradeOrder] after a market phase resolves.
enum TradeOrderStatus {
  pending,
  filled,
  partiallyFilled,
  unfilled,
  droppedInsufficientStockpile,
  droppedInsufficientCargo,
  rejected;

  String toJsonName() => name;

  static TradeOrderStatus fromJsonName(String value) {
    for (final s in TradeOrderStatus.values) {
      if (s.name == value) return s;
    }
    throw ModelValidationException.value(
      value,
      'value',
      'unknown TradeOrderStatus',
    );
  }
}

/// A single bid or offer submitted by a faction for a single commodity.
///
/// `priority` is a positive integer where 1 is highest precedence; lower
/// integer = higher precedence. `isFtp` is derived during matching when the
/// offer/bid pair belongs to FTP-linked factions.
class TradeOrder {
  TradeOrder({
    required this.commodityId,
    required this.type,
    required this.quantity,
    required this.priority,
    this.isFtp = false,
  }) {
    if (commodityId.isEmpty) {
      throw ModelValidationException.value(
        commodityId,
        'commodityId',
        'commodityId must not be empty',
      );
    }
    if (quantity < 0) {
      throw ModelValidationException.value(
        quantity,
        'quantity',
        'quantity must be non-negative',
      );
    }
    if (priority < 1) {
      throw ModelValidationException.value(
        priority,
        'priority',
        'priority must be >= 1',
      );
    }
  }

  final CommodityId commodityId;
  final TradeOrderType type;
  final int quantity;
  final int priority;
  final bool isFtp;

  TradeOrder copyWith({
    CommodityId? commodityId,
    TradeOrderType? type,
    int? quantity,
    int? priority,
    bool? isFtp,
  }) {
    return TradeOrder(
      commodityId: commodityId ?? this.commodityId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      isFtp: isFtp ?? this.isFtp,
    );
  }

  Map<String, dynamic> toJson() => {
    'commodityId': commodityId,
    'type': type.toJsonName(),
    'quantity': quantity,
    'priority': priority,
    'isFtp': isFtp,
  };

  static TradeOrder fromJson(Map<String, dynamic> json) {
    final id = json['commodityId'];
    if (id is! String) {
      throw ModelValidationException.value(
        id,
        'commodityId',
        'TradeOrder.fromJson: commodityId must be String',
      );
    }
    final typeRaw = json['type'];
    if (typeRaw is! String) {
      throw ModelValidationException.value(
        typeRaw,
        'type',
        'TradeOrder.fromJson: type must be String',
      );
    }
    final qtyRaw = json['quantity'];
    final qty = qtyRaw is int
        ? qtyRaw
        : int.tryParse(qtyRaw?.toString() ?? '');
    if (qty == null) {
      throw ModelValidationException.value(
        qtyRaw,
        'quantity',
        'TradeOrder.fromJson: quantity must be int',
      );
    }
    final prRaw = json['priority'];
    final pr = prRaw is int ? prRaw : int.tryParse(prRaw?.toString() ?? '');
    if (pr == null) {
      throw ModelValidationException.value(
        prRaw,
        'priority',
        'TradeOrder.fromJson: priority must be int',
      );
    }
    final ftp = json['isFtp'];
    return TradeOrder(
      commodityId: id,
      type: TradeOrderType.fromJsonName(typeRaw),
      quantity: qty,
      priority: pr,
      isFtp: ftp == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeOrder &&
          runtimeType == other.runtimeType &&
          commodityId == other.commodityId &&
          type == other.type &&
          quantity == other.quantity &&
          priority == other.priority &&
          isFtp == other.isFtp;

  @override
  int get hashCode => Object.hash(commodityId, type, quantity, priority, isFtp);

  @override
  String toString() =>
      'TradeOrder($type $commodityId × $quantity @ p$priority${isFtp ? ' FTP' : ''})';
}

/// Per-commodity activity snapshot for the previous market turn.
///
/// `totalBidQuantity` and `totalOfferQuantity` count only newly-submitted
/// quantities for the resolved turn (carry-forwards excluded), matching the
/// price discovery aggregation contract in
/// `SPEC/game/world-market.md` § Price discovery.
class MarketActivity {
  const MarketActivity({
    this.totalBidQuantity = 0,
    this.totalOfferQuantity = 0,
    this.filledQuantity = 0,
    this.priceChangePercent = 0.0,
  });

  final int totalBidQuantity;
  final int totalOfferQuantity;
  final int filledQuantity;
  final double priceChangePercent;

  static const empty = MarketActivity();

  Map<String, dynamic> toJson() => {
    'totalBidQuantity': totalBidQuantity,
    'totalOfferQuantity': totalOfferQuantity,
    'filledQuantity': filledQuantity,
    'priceChangePercent': priceChangePercent,
  };

  static MarketActivity fromJson(Map<String, dynamic> json) {
    int intOrZero(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double doubleOrZero(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return MarketActivity(
      totalBidQuantity: intOrZero(json['totalBidQuantity']),
      totalOfferQuantity: intOrZero(json['totalOfferQuantity']),
      filledQuantity: intOrZero(json['filledQuantity']),
      priceChangePercent: doubleOrZero(json['priceChangePercent']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketActivity &&
          runtimeType == other.runtimeType &&
          totalBidQuantity == other.totalBidQuantity &&
          totalOfferQuantity == other.totalOfferQuantity &&
          filledQuantity == other.filledQuantity &&
          priceChangePercent == other.priceChangePercent;

  @override
  int get hashCode => Object.hash(
    totalBidQuantity,
    totalOfferQuantity,
    filledQuantity,
    priceChangePercent,
  );
}

/// Aggregate market state stored on `Game` between turns.
class WorldMarketState {
  const WorldMarketState({
    this.prices = const <CommodityId, double>{},
    this.lastTurnActivity = const <CommodityId, MarketActivity>{},
    this.carryForwardOffersByFactionId =
        const <String, List<TradeOrder>>{},
    this.carryForwardBidsByFactionId =
        const <String, List<TradeOrder>>{},
  });

  final Map<CommodityId, double> prices;
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
    final populated = <CommodityId, double>{
      for (final entry in basePrices.entries) entry.key: entry.value.toDouble(),
    };
    return WorldMarketState(
      prices: Map.unmodifiable(populated),
      lastTurnActivity: const <CommodityId, MarketActivity>{},
    );
  }

  WorldMarketState copyWith({
    Map<CommodityId, double>? prices,
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
    final prices = <CommodityId, double>{};
    if (pricesRaw is Map<dynamic, dynamic>) {
      pricesRaw.forEach((key, value) {
        final id = key.toString();
        final price = value is num
            ? value.toDouble()
            : double.tryParse(value?.toString() ?? '') ?? 0.0;
        prices[id] = price;
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

/// A single offer/bid pairing executed in the market phase.
class FilledDeal {
  const FilledDeal({
    required this.sellerFactionId,
    required this.buyerFactionId,
    required this.commodityId,
    required this.quantity,
    required this.pricePerUnit,
    this.isFtpMatch = false,
  });

  final String sellerFactionId;
  final String buyerFactionId;
  final CommodityId commodityId;
  final int quantity;
  final double pricePerUnit;
  final bool isFtpMatch;

  Map<String, dynamic> toJson() => {
    'sellerFactionId': sellerFactionId,
    'buyerFactionId': buyerFactionId,
    'commodityId': commodityId,
    'quantity': quantity,
    'pricePerUnit': pricePerUnit,
    'isFtpMatch': isFtpMatch,
  };

  static FilledDeal fromJson(Map<String, dynamic> json) {
    int intOrZero(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double doubleOrZero(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return FilledDeal(
      sellerFactionId: json['sellerFactionId']?.toString() ?? '',
      buyerFactionId: json['buyerFactionId']?.toString() ?? '',
      commodityId: json['commodityId']?.toString() ?? '',
      quantity: intOrZero(json['quantity']),
      pricePerUnit: doubleOrZero(json['pricePerUnit']),
      isFtpMatch: json['isFtpMatch'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilledDeal &&
          runtimeType == other.runtimeType &&
          sellerFactionId == other.sellerFactionId &&
          buyerFactionId == other.buyerFactionId &&
          commodityId == other.commodityId &&
          quantity == other.quantity &&
          pricePerUnit == other.pricePerUnit &&
          isFtpMatch == other.isFtpMatch;

  @override
  int get hashCode => Object.hash(
    sellerFactionId,
    buyerFactionId,
    commodityId,
    quantity,
    pricePerUnit,
    isFtpMatch,
  );
}

/// Result envelope returned by the deal-matching engine for a turn.
class DealMatchResult {
  const DealMatchResult({
    this.filledDeals = const <FilledDeal>[],
    this.unfilledOffersByFactionId =
        const <String, List<TradeOrder>>{},
    this.unfilledBidsByFactionId =
        const <String, List<TradeOrder>>{},
    this.activityByCommodityId =
        const <CommodityId, MarketActivity>{},
  });

  final List<FilledDeal> filledDeals;
  final Map<String, List<TradeOrder>> unfilledOffersByFactionId;
  final Map<String, List<TradeOrder>> unfilledBidsByFactionId;
  final Map<CommodityId, MarketActivity> activityByCommodityId;

  static const empty = DealMatchResult();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DealMatchResult &&
          runtimeType == other.runtimeType &&
          _listEquals(filledDeals, other.filledDeals) &&
          _carryMapEquals(
            unfilledOffersByFactionId,
            other.unfilledOffersByFactionId,
          ) &&
          _carryMapEquals(
            unfilledBidsByFactionId,
            other.unfilledBidsByFactionId,
          ) &&
          _mapEquals(activityByCommodityId, other.activityByCommodityId);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(filledDeals),
    Object.hashAll(unfilledOffersByFactionId.keys),
    Object.hashAll(unfilledBidsByFactionId.keys),
    Object.hashAll(activityByCommodityId.keys),
  );
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
