// dart format off
// Compact non-GP extraction result assertions (Refs #3939 phase 3 slice 12).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for `computeNonGreatPowerExtraction` scenario rows.
class NonGpExtractionExpectation {
  const NonGpExtractionExpectation({this.empty = false, this.absentFaction, this.factionTotals, this.factionKeysUnordered, this.excludesCommodity, this.factionCommodityKeyCount});
  final bool empty;
  final String? absentFaction;
  final Map<String, Map<CommodityId, int>>? factionTotals;
  final Iterable<String>? factionKeysUnordered;
  final (String factionId, CommodityId commodity)? excludesCommodity;
  final (String factionId, int count)? factionCommodityKeyCount;
}
/// Compact faction-totals pin (Refs #3939 slice 62).
NonGpExtractionExpectation nonGpTotalsExpect(Map<String, Map<CommodityId, int>> factionTotals, {Iterable<String>? factionKeysUnordered, (String factionId, CommodityId commodity)? excludesCommodity, (String factionId, int count)? factionCommodityKeyCount}) => NonGpExtractionExpectation(factionTotals: factionTotals, factionKeysUnordered: factionKeysUnordered, excludesCommodity: excludesCommodity, factionCommodityKeyCount: factionCommodityKeyCount);
void assertNonGpExtractionExpectation(Map<String, Map<CommodityId, int>> result, NonGpExtractionExpectation expectation) {
  if (expectation.empty) {
    expect(result, isEmpty);
  }
  if (expectation.absentFaction != null) {
    expect(result, isNot(contains(expectation.absentFaction)));
  }
  if (expectation.factionTotals != null) {
    for (final entry in expectation.factionTotals!.entries) {
      if (entry.value.isEmpty) {
        expect(result, contains(entry.key));
      } else {
        expect(result[entry.key], equals(entry.value));
      }
    }
  }
  if (expectation.factionKeysUnordered != null) {
    expect(result.keys, unorderedEquals(expectation.factionKeysUnordered!.toList()));
  }
  if (expectation.excludesCommodity != null) {
    final (factionId, commodity) = expectation.excludesCommodity!;
    expect(result[factionId], isNot(contains(commodity)));
  }
  if (expectation.factionCommodityKeyCount != null) {
    final (factionId, count) = expectation.factionCommodityKeyCount!;
    expect(result[factionId]?.keys, hasLength(count));
  }
}
// dart format on
