// Table-driven merchant purchase-land candidate tile keys scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'merchant_purchase_land_candidate_tile_keys_expectations.dart';

/// One row in [merchantPurchaseLandCandidateTileKeysScenarios].
class MerchantPurchaseLandCandidateTileKeysScenario implements RefsScenario {
  const MerchantPurchaseLandCandidateTileKeysScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final MerchantPurchaseLandCandidateTileKeysTarget target;
  @override
  final String? refs;
}

void runMerchantPurchaseLandCandidateTileKeysScenario(
  MerchantPurchaseLandCandidateTileKeysScenario scenario,
) {
  runMerchantPurchaseLandCandidateTileKeysExpectation(scenario.target);
}

/// Canonical scenarios for merchant_purchase_land_candidate_tile_keys family tests.
List<MerchantPurchaseLandCandidateTileKeysScenario>
    merchantPurchaseLandCandidateTileKeysScenarios() => const [
          MerchantPurchaseLandCandidateTileKeysScenario(
            label: 'lists NW tribe tiles before Old World minor tiles',
            target: MerchantPurchaseLandCandidateTileKeysTarget.listsNwBeforeOw,
          ),
          MerchantPurchaseLandCandidateTileKeysScenario(
            label: 'matches province scan membership (deterministic NW-first sort)',
            target: MerchantPurchaseLandCandidateTileKeysTarget.matchesProvinceScanMembership,
          ),
          MerchantPurchaseLandCandidateTileKeysScenario(
            label: 'matches projection union over non-player owners (slice 14)',
            target: MerchantPurchaseLandCandidateTileKeysTarget.matchesProjectionUnion,
          ),
          MerchantPurchaseLandCandidateTileKeysScenario(
            label: 'excludes dev-exclusive reserved tiles like legacy path',
            target:
                MerchantPurchaseLandCandidateTileKeysTarget.excludesDevExclusiveReserved,
          ),
        ];
