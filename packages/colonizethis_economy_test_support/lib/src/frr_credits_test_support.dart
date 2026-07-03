// Shared helpers for First Right of Refusal credit (#2992 D4) unit suites.
// Refs #3427 step 15, #3823 Phase 3.

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show FilledDeal, PurchasedTileAttribution, PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Builds a [PurchasedTileIndex] for D4 helper tests via the `forTesting`
/// constructor so each test can declare exactly the attribution rows it
/// cares about without spinning up a full [Game].
PurchasedTileIndex idx(Iterable<PurchasedTileAttribution> rows) =>
    PurchasedTileIndex.forTesting(rows);

/// Builds a single purchased-tile attribution row.
PurchasedTileAttribution attr({
  required String tileKey,
  required String owningGpId,
  required String sourceFactionId,
  String provinceId = 'oldWorld|p1',
}) => PurchasedTileAttribution(
  tileKey: tileKey,
  owningGpId: owningGpId,
  sourceFactionId: sourceFactionId,
  provinceId: provinceId,
);

/// Builds a [FilledDeal] with sensible defaults for D4 credit tests.
FilledDeal deal({
  String seller = 'M1',
  required String buyer,
  CommodityId commodityId = 'timber',
  int quantity = 10,
  double pricePerUnit = 20.0,
  bool isFtpMatch = false,
  bool isFirstRightOfRefusalMatch = false,
  String? sellerOriginTileKey,
}) => FilledDeal(
  sellerFactionId: seller,
  buyerFactionId: buyer,
  commodityId: commodityId,
  quantity: quantity,
  pricePerUnit: pricePerUnit,
  isFtpMatch: isFtpMatch,
  isFirstRightOfRefusalMatch: isFirstRightOfRefusalMatch,
  sellerOriginTileKey: sellerOriginTileKey,
);
