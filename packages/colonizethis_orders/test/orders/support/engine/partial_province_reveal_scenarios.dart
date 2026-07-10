// Table-driven partial-province-reveal scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'partial_province_reveal_run_rows.dart';

/// One row in [partialProvinceRevealPrefixedIdsScenarios].
class PartialProvinceRevealScenario implements RefsScenario {
  const PartialProvinceRevealScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runPartialProvinceRevealScenario(PartialProvinceRevealScenario scenario) {
  scenario.run();
}

/// Scenarios for partiallyRevealedPrefixedProvinceIdsForPlayer.
List<PartialProvinceRevealScenario>
partialProvinceRevealPrefixedIdsScenarios() => const [
  PartialProvinceRevealScenario(
    label:
        'includes prefixed province id when land tiles mix unknown and known',
    run: pprRunIncludesPrefixedProvinceWhenLandTilesMixVisibility,
  ),
  PartialProvinceRevealScenario(
    label: 'excludes unprefixed province keys and uniform visibility',
    run: pprRunExcludesUnprefixedKeysAndUniformVisibility,
  ),
  PartialProvinceRevealScenario(
    label:
        'partial reveal ids resolve via provincesById to same set as allProvinces filter',
    run: pprRunPartialRevealIdsResolveViaProvincesById,
  ),
];

/// Scenarios for sortedProvincesForPartialRevealPrefixedIds.
List<PartialProvinceRevealScenario>
sortedProvincesForPartialRevealScenarios() => const [
  PartialProvinceRevealScenario(
    label: 'returns empty list without scanning when id set is empty',
    run: pprRunReturnsEmptyWithoutScanningWhenIdSetEmpty,
  ),
  PartialProvinceRevealScenario(
    label: 'returns matching provinces sorted by id',
    run: pprRunReturnsMatchingProvincesSortedById,
  ),
];
