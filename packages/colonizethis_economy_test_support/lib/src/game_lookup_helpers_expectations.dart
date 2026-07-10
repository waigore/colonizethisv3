// Compact game lookup helper assertions (Refs #3939 phase 3 slice 32).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Data-driven expectations for [buildProvinceIndex] rows.
class BuildProvinceIndexExpectation {
  const BuildProvinceIndexExpectation({
    this.expectedKeys,
    this.regionByProvinceId = const {},
    this.isEmpty = false,
  });

  final Set<String>? expectedKeys;
  final Map<String, String> regionByProvinceId;
  final bool isEmpty;
}

void assertBuildProvinceIndexExpectation(
  Map<String, Province> index,
  BuildProvinceIndexExpectation expectation,
) {
  if (expectation.isEmpty) {
    expect(index, isEmpty);
    return;
  }
  if (expectation.expectedKeys != null) {
    expect(index.keys.toSet(), expectation.expectedKeys);
  }
  for (final entry in expectation.regionByProvinceId.entries) {
    expect(index[entry.key]!.regionId, entry.value);
  }
}

/// Data-driven expectations for [collectPortTileKeys] rows.
class CollectPortTileKeysExpectation {
  const CollectPortTileKeysExpectation({this.expected, this.isEmpty = false});

  final Set<String>? expected;
  final bool isEmpty;
}

void assertCollectPortTileKeysExpectation(
  Set<String> portTileKeys,
  CollectPortTileKeysExpectation expectation,
) {
  if (expectation.isEmpty) {
    expect(portTileKeys, isEmpty);
    return;
  }
  expect(portTileKeys, expectation.expected);
}

/// One faction capital lookup pin for [capitalProvinceIdForFaction] /
/// [capitalRegionIdForFaction].
typedef CapitalFactionLookupPin = ({
  String factionId,
  String? provinceId,
  String? regionId,
});

/// Data-driven expectations for capital faction lookup rows.
class CapitalFactionLookupExpectation {
  const CapitalFactionLookupExpectation({required this.pins});

  final List<CapitalFactionLookupPin> pins;
}

void assertCapitalFactionLookupExpectation(
  Game game,
  CapitalFactionLookupExpectation expectation,
) {
  for (final pin in expectation.pins) {
    expect(capitalProvinceIdForFaction(game, pin.factionId), pin.provinceId);
    expect(capitalRegionIdForFaction(game, pin.factionId), pin.regionId);
  }
}
