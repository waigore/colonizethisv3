// Deal Book leftover reason widget fixtures (Refs #4500).

import 'package:colonizethis_models/colonizethis_models.dart';

MarketActivity dealBookActivityWithNotes({
  required String commodity,
  List<FilledDeal> deals = const <FilledDeal>[],
  List<MarketActivityNote> notes = const <MarketActivityNote>[],
  int totalBidQuantity = 0,
  int totalOfferQuantity = 0,
}) {
  return MarketActivity(
    totalBidQuantity: totalBidQuantity,
    totalOfferQuantity: totalOfferQuantity,
    filledQuantity: deals.fold<int>(0, (sum, d) => sum + d.quantity),
    deals: deals,
    notes: notes,
  );
}
