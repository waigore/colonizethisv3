// Deal Book leftover reason mapping (Refs #4500).
//
// Pure logic: maps human-scoped `MarketActivityNote`s and per-commodity
// volume fallbacks onto Still open / Did not stay open row view data per
// `SPEC/ui/trade-screen.md` § Deal Book leftover reasons.

library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Why a Still open leftover row shows a muted reason line.
enum DealBookStillOpenReasonKind {
  treasuryInsufficient,
  noMatchingSales,
  noMatchingBuys,
}

/// Why a Did not stay open row exists.
enum DealBookDropReasonKind {
  cargoInsufficient,
  stockpileInsufficient,
}

/// One Still open row with an optional resolver/fallback reason.
class DealBookStillOpenRowData {
  const DealBookStillOpenRowData({
    required this.order,
    this.reasonKind,
  });

  final TradeOrder order;
  final DealBookStillOpenReasonKind? reasonKind;
}

/// One Did not stay open row sourced from a drop note.
class DealBookDidNotStayOpenRowData {
  const DealBookDidNotStayOpenRowData({
    required this.commodityId,
    required this.quantity,
    required this.reasonKind,
  });

  final CommodityId commodityId;
  final int quantity;
  final DealBookDropReasonKind reasonKind;
}

/// Per-panel leftover reason rows for the Deal Book.
class DealBookPanelReasonData {
  const DealBookPanelReasonData({
    required this.stillOpenRows,
    required this.didNotStayOpenRows,
  });

  static const empty = DealBookPanelReasonData(
    stillOpenRows: <DealBookStillOpenRowData>[],
    didNotStayOpenRows: <DealBookDidNotStayOpenRowData>[],
  );

  final List<DealBookStillOpenRowData> stillOpenRows;
  final List<DealBookDidNotStayOpenRowData> didNotStayOpenRows;
}

/// Builds human-scoped Deal Book leftover reason rows from
/// [WorldMarketState.lastTurnActivity] notes and carry-forwards.
abstract final class DealBookReasonBuilder {
  DealBookReasonBuilder._();

  static DealBookPanelReasonData buildBids({
    required WorldMarketState worldMarket,
    required String playerId,
    required List<TradeOrder> unfilledBids,
  }) {
    return _build(
      worldMarket: worldMarket,
      playerId: playerId,
      unfilledOrders: unfilledBids,
      panelNoteKinds: const <MarketActivityNoteKind>{
        MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
        MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
      },
      dropNoteKind: MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
      dropReasonKind: DealBookDropReasonKind.cargoInsufficient,
      treasuryNoteKind:
          MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
      treasuryReasonKind: DealBookStillOpenReasonKind.treasuryInsufficient,
      fallbackReason: DealBookStillOpenReasonKind.noMatchingSales,
      fallbackApplies: (MarketActivity activity) =>
          activity.totalOfferQuantity == 0,
    );
  }

  static DealBookPanelReasonData buildOffers({
    required WorldMarketState worldMarket,
    required String playerId,
    required List<TradeOrder> unfilledOffers,
  }) {
    return _build(
      worldMarket: worldMarket,
      playerId: playerId,
      unfilledOrders: unfilledOffers,
      panelNoteKinds: const <MarketActivityNoteKind>{
        MarketActivityNoteKind.carryForwardDroppedStockpileInsufficient,
      },
      dropNoteKind:
          MarketActivityNoteKind.carryForwardDroppedStockpileInsufficient,
      dropReasonKind: DealBookDropReasonKind.stockpileInsufficient,
      treasuryNoteKind:
          MarketActivityNoteKind.bidPartialFillTreasuryInsufficient,
      treasuryReasonKind: DealBookStillOpenReasonKind.treasuryInsufficient,
      fallbackReason: DealBookStillOpenReasonKind.noMatchingBuys,
      fallbackApplies: (MarketActivity activity) =>
          activity.totalBidQuantity == 0,
    );
  }

  static DealBookPanelReasonData _build({
    required WorldMarketState worldMarket,
    required String playerId,
    required List<TradeOrder> unfilledOrders,
    required Set<MarketActivityNoteKind> panelNoteKinds,
    required MarketActivityNoteKind dropNoteKind,
    required DealBookDropReasonKind dropReasonKind,
    required MarketActivityNoteKind treasuryNoteKind,
    required DealBookStillOpenReasonKind treasuryReasonKind,
    required DealBookStillOpenReasonKind fallbackReason,
    required bool Function(MarketActivity activity) fallbackApplies,
  }) {
    final Map<CommodityId, List<MarketActivityNote>> notesByCommodity =
        _collectPanelNotesByCommodity(
      worldMarket: worldMarket,
      playerId: playerId,
      panelNoteKinds: panelNoteKinds,
    );

    final List<DealBookStillOpenRowData> stillOpen =
        unfilledOrders
            .map(
              (TradeOrder order) => DealBookStillOpenRowData(
                order: order,
                reasonKind: _stillOpenReasonForOrder(
                  order: order,
                  notesByCommodity: notesByCommodity,
                  worldMarket: worldMarket,
                  treasuryNoteKind: treasuryNoteKind,
                  treasuryReasonKind: treasuryReasonKind,
                  fallbackReason: fallbackReason,
                  fallbackApplies: fallbackApplies,
                ),
              ),
            )
            .toList(growable: false);

    final List<DealBookDidNotStayOpenRowData> drops =
        _collectDropRows(
      worldMarket: worldMarket,
      playerId: playerId,
      dropNoteKind: dropNoteKind,
      dropReasonKind: dropReasonKind,
    );

    return DealBookPanelReasonData(
      stillOpenRows: List<DealBookStillOpenRowData>.unmodifiable(stillOpen),
      didNotStayOpenRows:
          List<DealBookDidNotStayOpenRowData>.unmodifiable(drops),
    );
  }

  static Map<CommodityId, List<MarketActivityNote>>
  _collectPanelNotesByCommodity({
    required WorldMarketState worldMarket,
    required String playerId,
    required Set<MarketActivityNoteKind> panelNoteKinds,
  }) {
    final Map<CommodityId, List<MarketActivityNote>> notesByCommodity =
        <CommodityId, List<MarketActivityNote>>{};
    for (final MarketActivity activity
        in worldMarket.lastTurnActivity.values) {
      for (final MarketActivityNote note in activity.notes) {
        if (note.factionId != playerId ||
            !panelNoteKinds.contains(note.kind)) {
          continue;
        }
        notesByCommodity
            .putIfAbsent(note.commodityId, () => <MarketActivityNote>[])
            .add(note);
      }
    }
    return notesByCommodity;
  }

  static DealBookStillOpenReasonKind? _stillOpenReasonForOrder({
    required TradeOrder order,
    required Map<CommodityId, List<MarketActivityNote>> notesByCommodity,
    required WorldMarketState worldMarket,
    required MarketActivityNoteKind treasuryNoteKind,
    required DealBookStillOpenReasonKind treasuryReasonKind,
    required DealBookStillOpenReasonKind fallbackReason,
    required bool Function(MarketActivity activity) fallbackApplies,
  }) {
    final List<MarketActivityNote> notes =
        notesByCommodity[order.commodityId] ?? const <MarketActivityNote>[];
    if (notes.any((MarketActivityNote n) => n.kind == treasuryNoteKind)) {
      return treasuryReasonKind;
    }
    if (notes.isNotEmpty) {
      return null;
    }
    final MarketActivity activity =
        worldMarket.lastTurnActivity[order.commodityId] ??
            MarketActivity.empty;
    return fallbackApplies(activity) ? fallbackReason : null;
  }

  static List<DealBookDidNotStayOpenRowData> _collectDropRows({
    required WorldMarketState worldMarket,
    required String playerId,
    required MarketActivityNoteKind dropNoteKind,
    required DealBookDropReasonKind dropReasonKind,
  }) {
    final List<DealBookDidNotStayOpenRowData> drops =
        <DealBookDidNotStayOpenRowData>[];
    for (final MarketActivity activity
        in worldMarket.lastTurnActivity.values) {
      for (final MarketActivityNote note in activity.notes) {
        if (note.factionId != playerId || note.kind != dropNoteKind) {
          continue;
        }
        drops.add(
          DealBookDidNotStayOpenRowData(
            commodityId: note.commodityId,
            quantity: note.quantity,
            reasonKind: dropReasonKind,
          ),
        );
      }
    }
    return drops;
  }
}
