// Compact GP resource-extraction result assertions (Refs #3939 phase 3 slice 16).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Data-driven expectations for [ResourceExtractorScenario] rows.
class ResourceExtractorExpectation {
  const ResourceExtractorExpectation({
    this.playerId = 'pl1',
    this.land = const {},
    this.overseas = const {},
    this.landAbsent = const [],
    this.landEmpty = false,
    this.overseasEmpty = false,
    this.requirePlayer = true,
    this.custom,
  });

  final String playerId;
  final Map<String, int> land;
  final Map<String, int> overseas;
  final List<String> landAbsent;
  final bool landEmpty;
  final bool overseasEmpty;
  final bool requirePlayer;
  final void Function(Map<String, ExtractionTotals> result)? custom;
}

void assertResourceExtractorExpectation(
  Map<String, ExtractionTotals> result,
  ResourceExtractorExpectation expectation,
) {
  if (expectation.requirePlayer) {
    expect(result[expectation.playerId], isNotNull);
  }
  final totals = result[expectation.playerId];
  if (totals == null) {
    return;
  }
  if (expectation.landEmpty) {
    expect(totals.land, isEmpty);
  }
  if (expectation.overseasEmpty) {
    expect(totals.overseas, isEmpty);
  }
  for (final commodity in expectation.landAbsent) {
    expect(totals.land[commodity], isNull);
  }
  for (final entry in expectation.land.entries) {
    expect(totals.land[entry.key], entry.value);
  }
  for (final entry in expectation.overseas.entries) {
    expect(totals.overseas[entry.key], entry.value);
  }
  expectation.custom?.call(result);
}
