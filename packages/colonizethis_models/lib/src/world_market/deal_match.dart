part of '../world_market.dart';

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
    this.unfilledOffersByFactionId = const <String, List<TradeOrder>>{},
    this.unfilledBidsByFactionId = const <String, List<TradeOrder>>{},
    this.activityByCommodityId = const <CommodityId, MarketActivity>{},
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
