// Pins the canonical `criticalOwHoldPeaceTargets` and
// `stalledBelowQuotaGpLeadPeaceTargets` below-quota EXPAND peace deciders
// at their new home in `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `criticalOwHoldPeaceTargets` is the EXPAND "critical OW hold"
//     survival peace arm from `SPEC/ai/ai-architecture.md`
//     § Diplomacy targeting — "when OW holdings are at or below
//     `kFewOldWorldProvincesDefendThreshold` and any OW minor remains
//     (peace all GP wars)". It peaces every at-war Great Power once the
//     player has dropped at or below the defend threshold while still
//     strictly below the observer OW quota, so the GP can rebuild
//     without losing the few OW provinces it still holds.
//   * `stalledBelowQuotaGpLeadPeaceTargets` is the EXPAND "peace the
//     leaders, hold the blocker" arm from
//     `SPEC/ai/ai-architecture.md` § Diplomacy targeting. It peaces
//     at-war Great Powers that lead by the band-selected minimum
//     province deficit (`kUnwinnableSoleGpMinProvinceDeficit` on the
//     default-start row; `1` on the post-default 8–9 OW row) while
//     excluding the canonical OW invadable blocker on a GP-only
//     frontier.
//
// Sibling test coverage that this file complements (but does not duplicate):
//
//   * `diplomacy_planner_below_quota_peace_test.dart` exercises the
//     deciders through the diplomacy-planner orchestration chain (GP
//     wars at 6 OW, sole GP at 7 OW). Those flows resolve through the
//     canonical helpers pinned here.
//
// Behavioral invariants pinned at the canonical entry points:
//
//   1. `criticalOwHoldPeaceTargets` short-circuits to `const []` when
//      the at-war filter (`game.playerById(...) != null`) collapses to
//      empty.
//   2. `criticalOwHoldPeaceTargets` fires only inside the
//      `isBelowObserverConquestQuota && ownOw <=
//      kFewOldWorldProvincesDefendThreshold` AND-band; the boundary at
//      `ownOw == kFewOldWorldProvincesDefendThreshold + 1` returns
//      `const []` and the interior `ownOw == kFewOldWorldProvincesDefendThreshold`
//      returns the sorted at-war GP list.
//   3. `stalledBelowQuotaGpLeadPeaceTargets` short-circuits to
//      `const []` at the observer quota even when a GP enemy leads by
//      more than `kUnwinnableSoleGpMinProvinceDeficit` (the quota
//      hand-off to the quota-met deciders).
//   4. `stalledBelowQuotaGpLeadPeaceTargets` selects deficit band
//      `kUnwinnableSoleGpMinProvinceDeficit` on the default-start row
//      (`own <= kObserverDefaultStartOldWorldProvincesPerGp`) and band
//      `1` on the post-default row (8–9 OW). Both boundary rows are
//      pinned with positive and negative cases so the band-selector
//      cannot silently regress.
//   5. `stalledBelowQuotaGpLeadPeaceTargets` excludes the
//      `primaryInvadableOldWorldGpBlocker` on a GP-only invadable
//      frontier while keeping non-blocker GP foes that still satisfy
//      the deficit.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_planner_critical_ow_hold_and_stalled_lead_peace_cases.dart';


const String _gpOwn = 'gp_own';
const String _gpPartner = 'gp_partner';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';


void main() {
  registerExpandPhasePlannerCriticalOwHoldAndStalledLeadPeaceCases();
}
