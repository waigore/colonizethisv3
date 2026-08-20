// dart format off
// Table-driven projectProvinceExtraction scenarios (Refs #4064, #4550).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'extraction_fixture_support.dart';

/// One row for `projectProvinceExtraction` scenario tables.
typedef ProvinceExtractionProjectionScenario = ({
  String label,
  ProvinceExtractionProjectionPin pin,
  String? refs,
});

ProvinceExtractionProjectionScenario provinceProjectionScenario({
  required String label,
  required ProvinceExtractionProjectionPin pin,
  String? refs = '#4064',
}) => (label: label, pin: pin, refs: refs);

enum ProvinceExtractionProjectionPin {
  draftImproveIgnored,
  ownershipChangeRefreshesDisplay,
}

List<ProvinceExtractionProjectionScenario>
provinceExtractionProjectionScenarios() => [
  provinceProjectionScenario(
    label:
        'negative: mid-turn draft improve intent is not applied — only Game '
        'tile state drives projection',
    pin: ProvinceExtractionProjectionPin.draftImproveIgnored,
  ),
  provinceProjectionScenario(
    label:
        'ownership change: new owner projection appears without Extraction write',
    pin: ProvinceExtractionProjectionPin.ownershipChangeRefreshesDisplay,
  ),
];
// dart format on
