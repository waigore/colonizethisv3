// Table-driven merchant purchase-land candidate tile keys scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'merchant_purchase_land_candidate_tile_keys_run_rows.dart';

/// One row in [merchantPurchaseLandCandidateTileKeysScenarios].
class MerchantPurchaseLandCandidateTileKeysScenario implements RefsScenario {
  const MerchantPurchaseLandCandidateTileKeysScenario({
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

void runMerchantPurchaseLandCandidateTileKeysScenario(
  MerchantPurchaseLandCandidateTileKeysScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for merchant_purchase_land_candidate_tile_keys family tests.
List<MerchantPurchaseLandCandidateTileKeysScenario>
merchantPurchaseLandCandidateTileKeysScenarios() => const [
  MerchantPurchaseLandCandidateTileKeysScenario(
    label: 'lists NW tribe tiles before Old World minor tiles',
    run: mplRunListsNwBeforeOw,
  ),
  MerchantPurchaseLandCandidateTileKeysScenario(
    label: 'matches province scan membership (deterministic NW-first sort)',
    run: mplRunMatchesProvinceScanMembership,
  ),
  MerchantPurchaseLandCandidateTileKeysScenario(
    label: 'matches projection union over non-player owners (slice 14)',
    run: mplRunMatchesProjectionUnion,
  ),
  MerchantPurchaseLandCandidateTileKeysScenario(
    label: 'excludes dev-exclusive reserved tiles like legacy path',
    run: mplRunExcludesDevExclusiveReserved,
  ),
];
