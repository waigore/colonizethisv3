// In-process dispatch for `repo.economy_*` shared-helper manifest rules.
// Extracted from `ct_repo_lint_lib.dart` so that library stays under the
// `repo.dart_file_non_comment_line_size` 1000-NCL ceiling (Refs #4631).

import 'check_economy_bid_treasury_spend_shared.dart';
import 'check_economy_cost_check_shared_helper.dart';
import 'check_economy_dedup_credit_aggregation.dart';
import 'check_economy_dedup_port_tile_keys.dart';
import 'check_economy_force_feeding_shared_helper.dart';
import 'check_economy_grain_bonus_shared_helper.dart';
import 'check_economy_world_market_admission_shared.dart';

/// Dispatch helper for economy shared-helper manifest rules. Returns `null`
/// for non-matching rule ids so the caller falls back to generic dispatch.
int? tryRunEconomyRuleInProcess({
  required String ruleId,
  required String repoRoot,
}) {
  switch (ruleId) {
    case 'repo.economy_cost_check_shared_helper':
      return runCheckEconomyCostCheckSharedHelper(repoRoot);
    case 'repo.economy_force_feeding_shared_helper':
      return runCheckEconomyForceFeedingSharedHelper(repoRoot);
    case 'repo.economy_grain_bonus_shared_helper':
      return runCheckEconomyGrainBonusSharedHelper(repoRoot);
    case 'repo.economy_world_market_admission_shared':
      return runCheckEconomyWorldMarketAdmissionShared(repoRoot);
    case 'repo.economy_dedup_port_tile_keys':
      return runCheckEconomyDedupPortTileKeys(repoRoot);
    case 'repo.economy_dedup_credit_aggregation':
      return runCheckEconomyDedupCreditAggregation(repoRoot);
    case 'repo.economy_bid_treasury_spend_shared':
      return runCheckEconomyBidTreasurySpendShared(repoRoot);
    default:
      return null;
  }
}
