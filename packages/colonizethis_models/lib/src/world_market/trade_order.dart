part of '../world_market.dart';

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
    final qty = qtyRaw is int ? qtyRaw : int.tryParse(qtyRaw?.toString() ?? '');
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
  int get hashCode =>
      Object.hash(commodityId, type, quantity, priority, isFtp, originTileKey);

  @override
  String toString() =>
      'TradeOrder($type $commodityId × $quantity @ p$priority'
      '${isFtp ? ' FTP' : ''}'
      '${originTileKey != null ? ' tile:$originTileKey' : ''})';
}
