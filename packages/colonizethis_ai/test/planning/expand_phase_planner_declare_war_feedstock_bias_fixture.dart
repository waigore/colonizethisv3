// Shared fixtures for feedstock declare-war bias pins (Refs #4669 Slice B).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/expand_feedstock_seller_test_support.dart';

const String kFeedstockBiasSellerId = kExpandFeedstockSellerId;
const String kFeedstockBiasOldWorld = kExpandFeedstockOldWorld;
const String kFeedstockBiasMinor1 = 'minor1';
const String kFeedstockBiasMinor2 = 'minor2';
const String kFeedstockBiasMinor3 = 'minor3';
const String kFeedstockBiasGrainTile = kExpandFeedstockGrainTile;
const String kFeedstockBiasWoolTile = kExpandFeedstockWoolTile;

Province feedstockBiasMinorProvince(String id, String ownerId) =>
    Province(id: id, regionId: kFeedstockBiasOldWorld, ownerId: ownerId);

AIWorldSnapshot feedstockBiasSnapshot({
  required List<String> atWarWith,
  required List<String> invadableOw,
  List<String> adjacentOwners = const [],
}) {
  return AIWorldSnapshot(
    playerId: kFeedstockBiasSellerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 5,
      invadableProvinceIdsSorted: invadableOw,
      adjacentOwnerFactionIdsSorted: adjacentOwners,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}
