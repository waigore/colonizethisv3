// Shared First Right D5 AC fixture constants and helpers (Refs #2992 D5, #3939 slice 49).

import 'package:colonizethis_economy/colonizethis_economy.dart'
    show PurchasedTileAttribution, PurchasedTileIndex;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'frr_credits_test_support.dart';

const String kFrrIssueAcD5GpA = 'gpA';
const String kFrrIssueAcD5GpB = 'gpB';
const String kFrrIssueAcD5GpC = 'gpC';
const String kFrrIssueAcD5GpFtp = 'gpFtp';
const String kFrrIssueAcD5MinorM1 = 'M1';
const String kFrrIssueAcD5MinorM2 = 'M2';
const String kFrrIssueAcD5TileK1 = 'oldWorld|M1|0|0';
const String kFrrIssueAcD5TileK2 = 'oldWorld|M1|1|0';
const String kFrrIssueAcD5TileK3 = 'oldWorld|M2|0|0';
const String kFrrIssueAcD5ProvinceM1 = 'oldWorld|M1';
const String kFrrIssueAcD5ProvinceM2 = 'oldWorld|M2';

PurchasedTileAttribution frrD5Attr(
  String tileKey,
  String owningGpId,
  String sourceFactionId, [
  String provinceId = kFrrIssueAcD5ProvinceM1,
]) => attr(
  tileKey: tileKey,
  owningGpId: owningGpId,
  sourceFactionId: sourceFactionId,
  provinceId: provinceId,
);

PurchasedTileIndex frrD5IdxK1GpA() => idx([
  frrD5Attr(kFrrIssueAcD5TileK1, kFrrIssueAcD5GpA, kFrrIssueAcD5MinorM1),
]);

FilledDeal frrD5OtherBuyDeal({
  String seller = kFrrIssueAcD5MinorM1,
  String buyer = kFrrIssueAcD5GpB,
  int quantity = 10,
  double pricePerUnit = 20.0,
  String sellerOriginTileKey = kFrrIssueAcD5TileK1,
}) => deal(
  seller: seller,
  buyer: buyer,
  quantity: quantity,
  pricePerUnit: pricePerUnit,
  sellerOriginTileKey: sellerOriginTileKey,
);

FilledDeal frrD5FrrMatchDeal() => deal(
  seller: kFrrIssueAcD5MinorM1,
  buyer: kFrrIssueAcD5GpA,
  quantity: 10,
  pricePerUnit: 20.0,
  sellerOriginTileKey: kFrrIssueAcD5TileK1,
  isFirstRightOfRefusalMatch: true,
);
