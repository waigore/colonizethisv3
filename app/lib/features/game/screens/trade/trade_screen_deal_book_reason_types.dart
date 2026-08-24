// Deal Book leftover reason row types (Refs #4500 / #4642).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

/// Why a Still open leftover row shows a muted reason line.
enum DealBookStillOpenReasonKind {
  treasuryInsufficient,
  noMatchingSales,
  noMatchingBuys,
}

/// Why a Did not stay open row exists.
enum DealBookDropReasonKind { cargoInsufficient, stockpileInsufficient }

/// One Still open row with an optional resolver/fallback reason.
class DealBookStillOpenRowData {
  const DealBookStillOpenRowData({required this.order, this.reasonKind});

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
