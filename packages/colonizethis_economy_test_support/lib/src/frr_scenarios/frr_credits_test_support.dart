// Shared helpers for First Right of Refusal credit (#2992 D4) unit suites.
// Refs #3427 step 15, #3823 Phase 3, #3939 slice 44.

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show PurchasedTileAttribution, PurchasedTileIndex;
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

int frrAlwaysZeroRelation(String _, String __) => 0;

num Function(String, String) frrConstantRelation(int score) =>
    (_, __) => score;

/// Canonical k1 tile owned by gpA sourced from M1 (defensive / kickback suites).
PurchasedTileIndex frrIdxK1GpA() => idx([
      attr(tileKey: 'k1', owningGpId: 'gpA', sourceFactionId: 'M1'),
    ]);

/// Embassy map for source M1 only (Refs #3939 slice 44).
Map<String, num> Function(String sourceFactionId) frrEmbassyForM1(
  Map<String, num> relations,
) =>
    (src) => src == 'M1' ? relations : const {};
