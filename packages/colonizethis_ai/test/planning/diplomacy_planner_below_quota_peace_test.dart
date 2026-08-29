// Table-driven consolidation of the diplomacy below-quota peace helper /
// integration suites (Refs #3749 / #3941).
//
// Single contract file: core stalled/critical/weak/unwinnable helpers plus
// peer/near-quota ladders and stalled integration pins. Shared runners live
// in `diplomacy_planner_below_quota_peace_support.dart`; case bodies are
// split across topical `*_cases.dart` modules.
//
// Coverage is preserved 1:1 from the former part2/part3 shards — every row
// keeps the same fixture and the verbatim regression `reason`.

import 'diplomacy_planner_below_quota_peace_core_cases.dart';
import 'diplomacy_planner_below_quota_peace_near_quota_cases.dart';
import 'diplomacy_planner_below_quota_peace_near_quota_tail_cases.dart';
import 'diplomacy_planner_below_quota_peace_peer_cases.dart';
import 'diplomacy_planner_below_quota_peace_stalled_integration_cases.dart';

void main() {
  registerDiplomacyBelowQuotaPeaceCoreCases();
  registerDiplomacyBelowQuotaPeacePeerCases();
  registerDiplomacyBelowQuotaPeaceNearQuotaCases();
  registerDiplomacyBelowQuotaPeaceNearQuotaTailCases();
  registerDiplomacyBelowQuotaPeaceStalledIntegrationCases();
}
