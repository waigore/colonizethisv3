// Unit tests for the Phase 3 soft-weight wiring of the economy
// civilian-work threshold cap (Refs #2847).
//
// Mirrors the test pattern in:
//   - `phase_planner_conquest_colonial_pressure_floor_soft_weight_wiring_test.dart`
//   - `phase_planner_economy_build_pick_soft_weight_wiring_test.dart`
//   - `phase_planner_naval_colonial_pressure_floor_soft_weight_wiring_test.dart`
//
// Pins the contract of the new
// `economyColonialPressureCivilianWorkThresholdCap({colonialPressureWeight,
// uncappedThreshold})` helper that `_runEconomyDomainPlanners` consumes
// as the production source of truth for the colonial-pressure
// civilian-work threshold cap (previously a hard-coded
// `workThreshold = min(workThreshold, kColonialCivilianWorkThresholdCap)`
// step under the boolean `resolvePhaseEconomyColonialPressureActive`).
//
//   - `colonialPressureWeight <= 0.0` returns `uncappedThreshold`
//     unchanged (no cap applied — legacy `colonialPressure: false`
//     equivalent; future refactors that accidentally cap under zero
//     weight must fail this pin).
//
//   - `colonialPressureWeight == 1.0` returns
//     `kColonialCivilianWorkThresholdCap` exactly (identity-equal to the
//     legacy COLONIAL hard cap; future refactors must not weaken this
//     contract).
//
//   - Intermediate weights produce a continuous linear scaling between
//     the uncapped threshold and the hard cap
//     (`round(uncappedThreshold - (uncappedThreshold - cap) × w)`). The
//     early-sprint default curve weight (0.05 at OW <= 7) relaxes the
//     default-40 bar by a single point so the OW conquest sprint is not
//     dominated; the resource-need override floor (0.60) lowers the bar
//     so EXPAND-lock recovery civilian work can engage.
//
//   - The helper clamps out-of-range weights (`> 1.0 → 1.0`) so external
//     callers do not need to clamp upstream.
//
// The boolean Phase 2 resolver
// (`resolvePhaseEconomyColonialPressureActive`) and weight resolver
// (`resolvePhaseEconomyColonialPressureWeight`) remain pinned by their
// existing tests. This file targets only the helper that the Phase 3
// slice migrated from the legacy hard-coded cap magnitude to the
// soft-phase weight scaling.

import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group(
    'Phase 3 economy civilian-work threshold cap soft-weight wiring '
    '(Refs #2847)',
    () {
      const uncapped = 40;

      test(
        'colonialPressureWeight = 0.0 returns the uncapped threshold '
        '(no cap applied / regression guard)',
        () {
          // The Phase 3 contract: at zero weight no cap must apply so a
          // future refactor that caps the civilian-work bar under zero
          // weight (the legacy EXPAND / non-colonial path) surfaces here.
          expect(
            economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: 0.0,
              uncappedThreshold: uncapped,
            ),
            uncapped,
            reason:
                'colonialPressureWeight = 0.0 must return the uncapped '
                'threshold so the civilian-work bar is not lowered '
                '(legacy colonialPressure = false equivalent).',
          );
        },
      );

      test(
        'colonialPressureWeight = 1.0 identity-equal to legacy '
        'kColonialCivilianWorkThresholdCap (full-weight anchor)',
        () {
          // The Phase 3 contract: at full weight the helper must return
          // the legacy hard-phase cap magnitude exactly. A future
          // refactor that drifts this value would weaken the COLONIAL
          // civilian-work pull.
          expect(
            economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: 1.0,
              uncappedThreshold: uncapped,
            ),
            kColonialCivilianWorkThresholdCap,
            reason:
                'colonialPressureWeight = 1.0 must produce the legacy '
                'kColonialCivilianWorkThresholdCap '
                '($kColonialCivilianWorkThresholdCap) cap exactly.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.5 returns round(40 - 28 × 0.5) = 26 '
        '(continuous linear scaling)',
        () {
          // Sanity pin: the helper must scale linearly between the
          // endpoints so the civilian-work cap tracks the soft-phase NW
          // acquisition priority continuously instead of switching
          // on/off at the EXPAND→COLONIAL boundary.
          final expected =
              (uncapped - (uncapped - kColonialCivilianWorkThresholdCap) * 0.5)
                  .round();
          expect(
            economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: 0.5,
              uncappedThreshold: uncapped,
            ),
            expected,
            reason:
                'colonialPressureWeight = 0.5 must interpolate the cap '
                'linearly: round(40 - (40 - '
                '$kColonialCivilianWorkThresholdCap) × 0.5) = $expected.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.05 (early-sprint default curve) '
        'relaxes the default-40 bar to 39',
        () {
          // The early-sprint default curve sits at
          // `newWorldAcquisition = 0.05` for OW <= 7. The cap at this
          // weight must relax the default-40 bar by a single point so the
          // OW conquest sprint civilian/build balance is essentially
          // unchanged.
          final capAtEarlySprint =
              economyColonialPressureCivilianWorkThresholdCap(
                colonialPressureWeight: 0.05,
                uncappedThreshold: uncapped,
              );
          final expected =
              (uncapped - (uncapped - kColonialCivilianWorkThresholdCap) * 0.05)
                  .round();
          expect(
            capAtEarlySprint,
            expected,
            reason:
                'Early-sprint cap must equal round(40 - (40 - '
                '$kColonialCivilianWorkThresholdCap) × 0.05) = $expected.',
          );
          expect(
            capAtEarlySprint,
            greaterThan(uncapped - 2),
            reason:
                'Early-sprint cap ($capAtEarlySprint) must stay within a '
                'single point of the uncapped threshold ($uncapped) so '
                'the OW conquest sprint is not diverted by colonial '
                'pressure at OW <= 7.',
          );
        },
      );

      test(
        'colonialPressureWeight = 0.60 (resource-need override floor) '
        'lowers the bar to 23',
        () {
          // The EXPAND geographic peer-war lock recovery weight floor
          // (`newWorldAcquisition = 0.60` when treasury == 0 &&
          // newWorldProvincesOwned == 0 && boostTreasuryRecoveryCargo)
          // must lower the civilian-work bar so colonial Builder /
          // Merchant work can engage while a locked GP recovers
          // (Refs #2924).
          final expected =
              (uncapped - (uncapped - kColonialCivilianWorkThresholdCap) * 0.60)
                  .round();
          expect(
            economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: 0.60,
              uncappedThreshold: uncapped,
            ),
            expected,
            reason:
                'Resource-need override floor (0.60) must lower the cap '
                'to round(40 - (40 - $kColonialCivilianWorkThresholdCap) × '
                '0.60) = $expected.',
          );
        },
      );

      test(
        'colonialPressureWeight > 1.0 clamps to the full-weight anchor',
        () {
          // Defensive clamp pin: out-of-range weights must not lower the
          // cap below the legacy hard-phase magnitude.
          expect(
            economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: 2.0,
              uncappedThreshold: uncapped,
            ),
            kColonialCivilianWorkThresholdCap,
            reason:
                'colonialPressureWeight > 1.0 must clamp to 1.0 and '
                'produce the legacy cap exactly so unclamped upstream '
                'callers do not undershoot the legacy magnitude.',
          );
        },
      );

      test(
        'deterministic across repeated calls with identical inputs '
        '(Must-have #7)',
        () {
          // Pure-function determinism: a future change that introduces
          // stochastic behaviour into the weight-to-cap projection must
          // fail this pin.
          final a = economyColonialPressureCivilianWorkThresholdCap(
            colonialPressureWeight: 0.3,
            uncappedThreshold: uncapped,
          );
          final b = economyColonialPressureCivilianWorkThresholdCap(
            colonialPressureWeight: 0.3,
            uncappedThreshold: uncapped,
          );
          final c = economyColonialPressureCivilianWorkThresholdCap(
            colonialPressureWeight: 0.3,
            uncappedThreshold: uncapped,
          );
          expect(a, b, reason: 'two-call determinism');
          expect(b, c, reason: 'three-call determinism');
        },
      );

      test(
        'cap scales monotonically with colonialPressureWeight '
        '(non-increasing across [0.0, 1.0])',
        () {
          // Non-increasing contract: the civilian-work cap must never
          // rise as the soft-phase NW acquisition priority rises (a
          // higher NW priority lowers the bar so colonial civilian work
          // engages more readily).
          final samples = <double>[0.0, 0.05, 0.1, 0.2, 0.4, 0.6, 0.8, 1.0];
          var previous = uncapped + 1;
          for (final w in samples) {
            final current = economyColonialPressureCivilianWorkThresholdCap(
              colonialPressureWeight: w,
              uncappedThreshold: uncapped,
            );
            expect(
              current,
              lessThanOrEqualTo(previous),
              reason:
                  'Cap at colonialPressureWeight = $w ($current) must be '
                  '<= cap at the previous sample ($previous) — the '
                  'civilian-work bar is non-increasing as the NW '
                  'acquisition priority rises.',
            );
            previous = current;
          }
        },
      );
    },
  );
}
