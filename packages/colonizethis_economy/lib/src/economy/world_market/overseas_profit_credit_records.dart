/// Builds persisted overseas-profit credit rows from FRR aggregation (Refs #4226).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'embassy_kickback_accumulation.dart';
import 'first_right_credits.dart';
import 'first_right_profit.dart';
import 'purchased_tile_index.dart';

/// Maps [FirstRightCreditsResult] into per-GP [OverseasProfitCreditRecord] lists
/// for [WorldMarketState.lastTurnOverseasProfitCreditsByGpId].
///
/// Tile-owner rows come from [FirstRightCreditsResult.creditedDeals]. Embassy
/// kickback rows are emitted per deal per embassy-holding GP (R8.3) when
/// [embassyGpRelationsFor] is supplied — same inputs as
/// [computeFirstRightCredits].
Map<String, List<OverseasProfitCreditRecord>>
buildOverseasProfitCreditRecordsByGpId({
  required FirstRightCreditsResult credits,
  required Iterable<FilledDeal> filledDeals,
  required PurchasedTileIndex? purchasedTileIndex,
  required Map<String, num> Function(String sourceFactionId)?
  embassyGpRelationsFor,
}) {
  final byGp = <String, List<OverseasProfitCreditRecord>>{};

  void addRecord(String gpId, OverseasProfitCreditRecord record) {
    if (gpId.isEmpty || record.profitTreasury <= 0) return;
    byGp.putIfAbsent(gpId, () => <OverseasProfitCreditRecord>[]).add(record);
  }

  for (final credit in credits.creditedDeals) {
    final treasury = credit.profit.profitTreasury.round();
    if (treasury <= 0) continue;
    addRecord(
      credit.owningGpId,
      OverseasProfitCreditRecord(
        creditKind: OverseasProfitCreditKind.tileOwnerShare,
        commodityId: credit.deal.commodityId,
        quantity: credit.deal.quantity,
        profitTreasury: treasury,
        buyerFactionId: credit.deal.buyerFactionId,
        sourceFactionId: credit.sourceFactionId,
      ),
    );
  }

  final hasTileIndex =
      purchasedTileIndex != null && purchasedTileIndex.isNotEmpty;
  if (embassyGpRelationsFor != null) {
    for (final deal in filledDeals) {
      if (deal.quantity <= 0 || deal.pricePerUnit <= 0.0) continue;

      final tileKey = deal.sellerOriginTileKey;
      final attribution = (hasTileIndex && tileKey != null && tileKey.isNotEmpty)
          ? purchasedTileIndex.attributionForTileKey(tileKey)
          : null;
      final owningGpId = attribution?.owningGpId ?? '';
      final sourceFactionId =
          attribution?.sourceFactionId ?? deal.sellerFactionId;
      if (sourceFactionId.isEmpty) continue;

      final embassyRelations = embassyGpRelationsFor(sourceFactionId);
      for (final entry in embassyRelations.entries) {
        final gpId = entry.key;
        if (gpId.isEmpty || gpId == owningGpId) continue;
        final kickback = computeEmbassyKickback(
          relationScore: entry.value,
          filledQuantity: deal.quantity,
          pricePerUnit: deal.pricePerUnit,
        );
        final treasury = kickback.round();
        if (treasury <= 0) continue;
        addRecord(
          gpId,
          OverseasProfitCreditRecord(
            creditKind: OverseasProfitCreditKind.embassyKickback,
            commodityId: deal.commodityId,
            quantity: deal.quantity,
            profitTreasury: treasury,
            buyerFactionId: deal.buyerFactionId,
            sourceFactionId: sourceFactionId,
          ),
        );
      }
    }
  }

  return Map<String, List<OverseasProfitCreditRecord>>.unmodifiable(
    {
      for (final entry in byGp.entries)
        entry.key: List<OverseasProfitCreditRecord>.unmodifiable(entry.value),
    },
  );
}

/// Combined integer treasury credit per GP from [recordsByGpId].
Map<String, int> overseasProfitTreasuryTotalByGpId(
  Map<String, List<OverseasProfitCreditRecord>> recordsByGpId,
) {
  final totals = <String, int>{};
  for (final entry in recordsByGpId.entries) {
    var sum = 0;
    for (final record in entry.value) {
      sum += record.profitTreasury;
    }
    if (sum > 0) {
      totals[entry.key] = sum;
    }
  }
  return Map<String, int>.unmodifiable(totals);
}
