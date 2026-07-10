// Table-driven partial-province-reveal scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'partial_province_reveal_expectations.dart';

/// One row in [partialProvinceRevealPrefixedIdsScenarios].
class PartialProvinceRevealScenario implements RefsScenario {
  const PartialProvinceRevealScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final PartialProvinceRevealTarget target;
  @override
  final String? refs;
}

void runPartialProvinceRevealScenario(PartialProvinceRevealScenario scenario) {
  runPartialProvinceRevealExpectation(scenario.target);
}

/// Scenarios for partiallyRevealedPrefixedProvinceIdsForPlayer.
List<PartialProvinceRevealScenario>
partialProvinceRevealPrefixedIdsScenarios() => const [
  PartialProvinceRevealScenario(
    label:
        'includes prefixed province id when land tiles mix unknown and known',
    target: PartialProvinceRevealTarget
        .includesPrefixedProvinceWhenLandTilesMixVisibility,
  ),
  PartialProvinceRevealScenario(
    label: 'excludes unprefixed province keys and uniform visibility',
    target:
        PartialProvinceRevealTarget.excludesUnprefixedKeysAndUniformVisibility,
  ),
  PartialProvinceRevealScenario(
    label:
        'partial reveal ids resolve via provincesById to same set as allProvinces filter',
    target: PartialProvinceRevealTarget.partialRevealIdsResolveViaProvincesById,
  ),
];

/// Scenarios for sortedProvincesForPartialRevealPrefixedIds.
List<PartialProvinceRevealScenario>
sortedProvincesForPartialRevealScenarios() => const [
  PartialProvinceRevealScenario(
    label: 'returns empty list without scanning when id set is empty',
    target:
        PartialProvinceRevealTarget.returnsEmptyWithoutScanningWhenIdSetEmpty,
  ),
  PartialProvinceRevealScenario(
    label: 'returns matching provinces sorted by id',
    target: PartialProvinceRevealTarget.returnsMatchingProvincesSortedById,
  ),
];
