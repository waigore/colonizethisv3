/// Last-turn overseas-profit credit row persisted on [WorldMarketState].
///
/// SPEC: `SPEC/program/world-market-resolution.md` § Step F (Refs #4226).
library;

import '../stockpile.dart';

/// Kind of overseas-profit treasury credit credited to a Great Power.
enum OverseasProfitCreditKind {
  /// Tile-owner full relation-linear share (#3753 R8.2).
  tileOwnerShare,

  /// Embassy-holder kickback (#3753 R8.3).
  embassyKickback,
}

/// One overseas-profit credit row for Deal Book / observer audit.
class OverseasProfitCreditRecord {
  const OverseasProfitCreditRecord({
    required this.creditKind,
    required this.commodityId,
    required this.quantity,
    required this.profitTreasury,
    this.buyerFactionId,
    this.sourceFactionId,
  });

  final OverseasProfitCreditKind creditKind;
  final CommodityId commodityId;
  final int quantity;

  /// Integer treasury units credited (rounded per economy path).
  final int profitTreasury;
  final String? buyerFactionId;
  final String? sourceFactionId;

  Map<String, dynamic> toJson() => {
    'creditKind': creditKind.name,
    'commodityId': commodityId,
    'quantity': quantity,
    'profitTreasury': profitTreasury,
    if (buyerFactionId != null) 'buyerFactionId': buyerFactionId,
    if (sourceFactionId != null) 'sourceFactionId': sourceFactionId,
  };

  static OverseasProfitCreditRecord fromJson(Map<String, dynamic> json) {
    final kindRaw = json['creditKind']?.toString() ?? '';
    final kind = OverseasProfitCreditKind.values.firstWhere(
      (k) => k.name == kindRaw,
      orElse: () => OverseasProfitCreditKind.tileOwnerShare,
    );
    return OverseasProfitCreditRecord(
      creditKind: kind,
      commodityId: json['commodityId']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      profitTreasury: (json['profitTreasury'] as num?)?.toInt() ?? 0,
      buyerFactionId: json['buyerFactionId']?.toString(),
      sourceFactionId: json['sourceFactionId']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverseasProfitCreditRecord &&
          runtimeType == other.runtimeType &&
          creditKind == other.creditKind &&
          commodityId == other.commodityId &&
          quantity == other.quantity &&
          profitTreasury == other.profitTreasury &&
          buyerFactionId == other.buyerFactionId &&
          sourceFactionId == other.sourceFactionId;

  @override
  int get hashCode => Object.hash(
    creditKind,
    commodityId,
    quantity,
    profitTreasury,
    buyerFactionId,
    sourceFactionId,
  );
}
