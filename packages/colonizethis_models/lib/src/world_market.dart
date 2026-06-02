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
///
/// `originTileKey` attributes an offer to a specific minor/tribe tile so
/// the deal matcher can apply the world-market First Right of Refusal
/// override per `SPEC/game/world-market-first-right-of-refusal.md`. It is
/// always `null` on bids and on Great-Power-submitted offers; only
/// minor/tribe auto-offers (#2991 C2 onwards) populate it. Storing the
/// origin tile here keeps the deal matcher pure: it can resolve the
/// owning Great Power via [PurchasedTileIndex] without re-querying
/// `WorldState`.
class TradeOrder {
  TradeOrder({
    required this.commodityId,
    required this.type,
    required this.quantity,
    required this.priority,
    this.isFtp = false,
    this.originTileKey,
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
    if (originTileKey != null && originTileKey!.isEmpty) {
      throw ModelValidationException.value(
        originTileKey,
        'originTileKey',
        'originTileKey must be null or non-empty',
      );
    }
  }

  final CommodityId commodityId;
  final TradeOrderType type;
  final int quantity;
  final int priority;
  final bool isFtp;
  final String? originTileKey;

  TradeOrder copyWith({
    CommodityId? commodityId,
    TradeOrderType? type,
    int? quantity,
    int? priority,
    bool? isFtp,
    Object? originTileKey = _copyWithUnset,
  }) {
    return TradeOrder(
      commodityId: commodityId ?? this.commodityId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      isFtp: isFtp ?? this.isFtp,
      originTileKey: identical(originTileKey, _copyWithUnset)
          ? this.originTileKey
          : originTileKey as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'commodityId': commodityId,
    'type': type.toJsonName(),
    'quantity': quantity,
    'priority': priority,
    'isFtp': isFtp,
    if (originTileKey != null) 'originTileKey': originTileKey,
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
    final originRaw = json['originTileKey'];
    final origin = originRaw is String && originRaw.isNotEmpty
        ? originRaw
        : null;
    return TradeOrder(
      commodityId: id,
      type: TradeOrderType.fromJsonName(typeRaw),
      quantity: qty,
      priority: pr,
      isFtp: ftp == true,
      originTileKey: origin,
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
          isFtp == other.isFtp &&
          originTileKey == other.originTileKey;

  @override
  int get hashCode => Object.hash(
    commodityId,
    type,
    quantity,
    priority,
    isFtp,
    originTileKey,
  );

  @override
  String toString() =>
      'TradeOrder($type $commodityId × $quantity @ p$priority'
      '${isFtp ? ' FTP' : ''}'
      '${originTileKey != null ? ' tile:$originTileKey' : ''})';
}

const Object _copyWithUnset = Object();

/// Categorical reason recorded on a [MarketActivityNote] when the world
/// market phase drops a carry-forward order or otherwise emits an
/// audit-grade event for the Deal Book / observer tooling per
/// `SPEC/program/world-market-resolution.md` § Step A Gather (Step A.3) and
/// § Step F Activity rollup.
enum MarketActivityNoteKind {
  /// Carry-forward offer dropped at start of phase because the submitter's
  /// current stockpile for the order's commodity is below the order's
  /// quantity (`SPEC/game/world-market.md` § Order persistence
  /// "Carry-forward drop on stockpile shortfall").
  carryForwardDroppedStockpileInsufficient,

  /// Carry-forward bid dropped at start of phase because the submitter's
  /// current trade cargo capacity is below the order's quantity
  /// (`SPEC/game/world-market.md` § Order persistence
  /// "Carry-forward drop on cargo shortfall").
  carryForwardDroppedCargoInsufficient,

  /// Bid partially filled (or fully suppressed) inside the deal matcher
  /// because the buyer's start-of-phase treasury budget could not cover
  /// the bid's full notional at the matched price. Recorded once per
  /// truncated bid per `SPEC/program/world-market-resolution.md` § Step C
  /// (treasury clamp, Refs #3115). The note's `quantity` is the original
  /// submitted bid quantity; the residual carry-forward is preserved in
  /// `DealMatchResult.unfilledBidsByFactionId` for next-turn re-entry.
  bidPartialFillTreasuryInsufficient;

  String toJsonName() => name;

  static MarketActivityNoteKind fromJsonName(String value) {
    for (final k in MarketActivityNoteKind.values) {
      if (k.name == value) return k;
    }
    throw ModelValidationException.value(
      value,
      'value',
      'unknown MarketActivityNoteKind',
    );
  }
}

/// Single audit-grade event attached to a [MarketActivity] entry for the
/// commodity the event relates to. Used by the Deal Book UI and the
/// observer/AI traces to explain dropped carry-forwards and other
/// phase-internal decisions that do not produce a `FilledDeal` but do
/// affect the submitter's order book.
///
/// Notes are pure value objects: immutable, JSON-serializable, value-equal.
class MarketActivityNote {
  const MarketActivityNote({
    required this.kind,
    required this.factionId,
    required this.commodityId,
    required this.quantity,
  });

  /// Categorical reason for the note.
  final MarketActivityNoteKind kind;

  /// Faction id whose order was affected (e.g. the dropped carry-forward
  /// submitter). Always non-empty for the carry-forward drop kinds.
  final String factionId;

  /// Commodity id the note is scoped to. Matches the commodity key the
  /// note will be recorded under inside `MarketActivity.notes`.
  final CommodityId commodityId;

  /// Affected quantity in commodity units. For drop kinds this is the
  /// quantity that did **not** survive into matching (i.e. the original
  /// carry-forward quantity).
  final int quantity;

  Map<String, dynamic> toJson() => {
    'kind': kind.toJsonName(),
    'factionId': factionId,
    'commodityId': commodityId,
    'quantity': quantity,
  };

  static MarketActivityNote fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'];
    if (kindRaw is! String) {
      throw ModelValidationException.value(
        kindRaw,
        'kind',
        'MarketActivityNote.fromJson: kind must be String',
      );
    }
    final factionRaw = json['factionId'];
    if (factionRaw is! String) {
      throw ModelValidationException.value(
        factionRaw,
        'factionId',
        'MarketActivityNote.fromJson: factionId must be String',
      );
    }
    final commodityRaw = json['commodityId'];
    if (commodityRaw is! String) {
      throw ModelValidationException.value(
        commodityRaw,
        'commodityId',
        'MarketActivityNote.fromJson: commodityId must be String',
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
        'MarketActivityNote.fromJson: quantity must be int',
      );
    }
    return MarketActivityNote(
      kind: MarketActivityNoteKind.fromJsonName(kindRaw),
      factionId: factionRaw,
      commodityId: commodityRaw,
      quantity: qty,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketActivityNote &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          factionId == other.factionId &&
          commodityId == other.commodityId &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(kind, factionId, commodityId, quantity);

  @override
  String toString() =>
      'MarketActivityNote(${kind.name} faction=$factionId '
      'commodity=$commodityId qty=$quantity)';
}

/// Per-commodity activity snapshot for the previous market turn.
///
/// `totalBidQuantity` and `totalOfferQuantity` count only newly-submitted
/// quantities for the resolved turn (carry-forwards excluded), matching the
/// price discovery aggregation contract in
/// `SPEC/game/world-market.md` § Price discovery.
///
/// `deals` carries the per-commodity sequence of [FilledDeal] entries that
/// the deal matcher produced for the resolved turn (see
/// `SPEC/program/world-market-resolution.md` § Step F Activity rollup and
/// § Data model). The Deal Book UI (`#2993` E6) consumes this list,
/// filtered by buyer/seller faction id, to render the player's ledger.
/// The list is **always** stored unmodifiable; callers must not mutate it
/// in place.
///
/// `notes` carries audit-grade events scoped to this commodity for the
/// resolved turn (currently: dropped carry-forwards per
/// `SPEC/program/world-market-resolution.md` § Step A Gather). The list is
/// **always** stored unmodifiable; callers must not mutate it in place.
class MarketActivity {
  const MarketActivity({
    this.totalBidQuantity = 0,
    this.totalOfferQuantity = 0,
    this.filledQuantity = 0,
    this.priceChangePercent = 0.0,
    this.deals = const <FilledDeal>[],
    this.notes = const <MarketActivityNote>[],
  });

  final int totalBidQuantity;
  final int totalOfferQuantity;
  final int filledQuantity;
  final double priceChangePercent;
  final List<FilledDeal> deals;
  final List<MarketActivityNote> notes;

  static const empty = MarketActivity();

  Map<String, dynamic> toJson() => {
    'totalBidQuantity': totalBidQuantity,
    'totalOfferQuantity': totalOfferQuantity,
    'filledQuantity': filledQuantity,
    'priceChangePercent': priceChangePercent,
    if (deals.isNotEmpty)
      'deals': [for (final d in deals) d.toJson()],
    if (notes.isNotEmpty)
      'notes': [for (final n in notes) n.toJson()],
  };

  static MarketActivity fromJson(Map<String, dynamic> json) {
    int intOrZero(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double doubleOrZero(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    final dealsRaw = json['deals'];
    final deals = <FilledDeal>[];
    if (dealsRaw is List<dynamic>) {
      for (final entry in dealsRaw) {
        if (entry is Map<dynamic, dynamic>) {
          deals.add(FilledDeal.fromJson(Map<String, dynamic>.from(entry)));
        }
      }
    }

    final notesRaw = json['notes'];
    final notes = <MarketActivityNote>[];
    if (notesRaw is List<dynamic>) {
      for (final entry in notesRaw) {
        if (entry is Map<dynamic, dynamic>) {
          notes.add(
            MarketActivityNote.fromJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }

    return MarketActivity(
      totalBidQuantity: intOrZero(json['totalBidQuantity']),
      totalOfferQuantity: intOrZero(json['totalOfferQuantity']),
      filledQuantity: intOrZero(json['filledQuantity']),
      priceChangePercent: doubleOrZero(json['priceChangePercent']),
      deals: deals.isEmpty
          ? const <FilledDeal>[]
          : List<FilledDeal>.unmodifiable(deals),
      notes: notes.isEmpty
          ? const <MarketActivityNote>[]
          : List<MarketActivityNote>.unmodifiable(notes),
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
          priceChangePercent == other.priceChangePercent &&
          _listEquals(deals, other.deals) &&
          _listEquals(notes, other.notes);

  @override
  int get hashCode => Object.hash(
    totalBidQuantity,
    totalOfferQuantity,
    filledQuantity,
    priceChangePercent,
    Object.hashAll(deals),
    Object.hashAll(notes),
  );
}

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

/// A single offer/bid pairing executed in the market phase.
///
/// `isFirstRightOfRefusalMatch` is set when the deal matcher applied the
/// First Right of Refusal override per
/// `SPEC/game/world-market-first-right-of-refusal.md` — the buyer is the
/// owning Great Power for a purchased minor/tribe tile and the offer's
/// `originTileKey` resolved via `PurchasedTileIndex`. FRR matches always
/// take priority above FTP within the matcher; the flag also serves as
/// an audit signal for D4 treasury transfers and Deal Book UI.
///
/// `sellerOriginTileKey` mirrors the offer-side `TradeOrder.originTileKey`
/// when the matcher consumed an attributed offer (`null` for offers with
/// no origin tile). D4 treasury-transfer callers use it together with
/// `PurchasedTileIndex.attributionForTileKey` to identify deals that
/// landed on a different buyer than the owning Great Power (which is
/// where overseas-profit credits accrue per
/// `SPEC/game/world-market-first-right-of-refusal.md` § Treasury transfer
/// (D4)).
class FilledDeal {
  const FilledDeal({
    required this.sellerFactionId,
    required this.buyerFactionId,
    required this.commodityId,
    required this.quantity,
    required this.pricePerUnit,
    this.isFtpMatch = false,
    this.isFirstRightOfRefusalMatch = false,
    this.sellerOriginTileKey,
  });

  final String sellerFactionId;
  final String buyerFactionId;
  final CommodityId commodityId;
  final int quantity;
  final double pricePerUnit;
  final bool isFtpMatch;
  final bool isFirstRightOfRefusalMatch;

  /// Offer-side `TradeOrder.originTileKey` for this deal, or `null` when
  /// the offer carried no origin tile. Preserved by the deal matcher so
  /// D4 (overseas-profit transfer) callers can resolve purchased-tile
  /// attribution without re-querying matcher internals.
  final String? sellerOriginTileKey;

  Map<String, dynamic> toJson() => {
    'sellerFactionId': sellerFactionId,
    'buyerFactionId': buyerFactionId,
    'commodityId': commodityId,
    'quantity': quantity,
    'pricePerUnit': pricePerUnit,
    'isFtpMatch': isFtpMatch,
    if (isFirstRightOfRefusalMatch)
      'isFirstRightOfRefusalMatch': isFirstRightOfRefusalMatch,
    if (sellerOriginTileKey != null) 'sellerOriginTileKey': sellerOriginTileKey,
  };

  static FilledDeal fromJson(Map<String, dynamic> json) {
    int intOrZero(Object? v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    double doubleOrZero(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    final tileKey = json['sellerOriginTileKey'];
    return FilledDeal(
      sellerFactionId: json['sellerFactionId']?.toString() ?? '',
      buyerFactionId: json['buyerFactionId']?.toString() ?? '',
      commodityId: json['commodityId']?.toString() ?? '',
      quantity: intOrZero(json['quantity']),
      pricePerUnit: doubleOrZero(json['pricePerUnit']),
      isFtpMatch: json['isFtpMatch'] == true,
      isFirstRightOfRefusalMatch: json['isFirstRightOfRefusalMatch'] == true,
      sellerOriginTileKey: tileKey is String && tileKey.isNotEmpty
          ? tileKey
          : null,
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
          isFtpMatch == other.isFtpMatch &&
          isFirstRightOfRefusalMatch == other.isFirstRightOfRefusalMatch &&
          sellerOriginTileKey == other.sellerOriginTileKey;

  @override
  int get hashCode => Object.hash(
    sellerFactionId,
    buyerFactionId,
    commodityId,
    quantity,
    pricePerUnit,
    isFtpMatch,
    isFirstRightOfRefusalMatch,
    sellerOriginTileKey,
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
