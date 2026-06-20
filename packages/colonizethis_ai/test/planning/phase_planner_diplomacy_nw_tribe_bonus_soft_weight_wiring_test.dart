// Unit tests for the Phase 3 soft-weight wiring of the diplomacy
// declare-war NW-tribe colonial-acquisition bonuses (Refs #2847).
//
// Mirrors the test pattern in:
//   - `phase_planner_conquest_colonial_pressure_floor_soft_weight_wiring_test.dart`
//   - `phase_planner_diplomacy_declare_war_soft_weight_wiring_test.dart`
//   - `phase_planner_goal_filter_soft_weight_wiring_test.dart`
//
// Pins the contract of the new
// `declareWarColonialNwTribeDominanceBonus({nwAcquisitionWeight})` and
// `declareWarColonialNwTribePriorityOverOwMinorBonus({nwAcquisitionWeight})`
// helpers that `_declareWarColonialNwTribeBonuses`
// (`diplomatic_candidate_scoring_declare_war_bonuses.dart`) consumes as the
// production source of truth for the NW-tribe declare-war addends — previously
// applied at their full `kDeclareWarColonialNwTribeDominanceBonus` /
// `kDeclareWarColonialNwTribePriorityOverOwMinorBonus` magnitude on the binary
// `colonialPressure` (`nwAcquisitionWeight > 0.0`) gate.
//
//   - `nwAcquisitionWeight == 1.0` returns the legacy constant exactly
//     (identity-equal full-weight anchor; future refactors must not weaken
//     this contract).
//
//   - `nwAcquisitionWeight <= 0.0` returns `0` (legacy `colonialPressure:
//     false` equivalent; future refactors that accidentally apply a bonus
//     under zero weight must fail this pin).
//
//   - Intermediate weights produce continuous linear scaling
//     (`round(base × w)`). The early-sprint default curve weight (`0.05` at
//     OW <= 7) collapses the dominance addend to `5` and the priority addend
//     to `18`, keeping the OW conquest sprint dominant.
//
//   - The helpers clamp out-of-range weights (`> 1.0 -> 1.0`,
//     `< 0.0 -> 0.0`) so external callers do not need to clamp upstream.
//
// The boolean Phase 2 resolver
// (`resolvePhaseDiplomacyDeclareWarColonialPressureActive`) and weight
// resolvers (`resolvePhaseDiplomacyDeclareWarColonialPressureWeight`,
// `resolvePhaseDiplomacyDeclareWarOldWorldConquestWeight`) remain pinned by
// `phase_planner_declare_war_targets_test.dart` and
// `phase_planner_priority_weight_resolvers_test.dart` respectively. This file
// targets only the helpers that the Phase 3 slice migrated from the legacy
// hard-coded full-magnitude addends to the soft-phase weight scaling.

import 'package:colonizethis_ai/src/planning/phase_planner_diplomacy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Phase 3 diplomacy declare-war NW-tribe bonus soft-weight wiring '
      '(Refs #2847)', () {
    test('nwAcquisitionWeight = 1.0 identity-equal to legacy '
        'kDeclareWarColonialNwTribeDominanceBonus (full-weight anchor)', () {
      // At full NW priority the dominance addend must equal the legacy
      // hard-phase magnitude exactly; drift here would silently weaken
      // (or inflate) the COLONIAL NW-tribe declare-war pull.
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 1.0),
        kDeclareWarColonialNwTribeDominanceBonus,
        reason:
            'nwAcquisitionWeight = 1.0 must produce the legacy '
            'kDeclareWarColonialNwTribeDominanceBonus '
            '($kDeclareWarColonialNwTribeDominanceBonus) exactly.',
      );
    });

    test('nwAcquisitionWeight = 1.0 identity-equal to legacy '
        'kDeclareWarColonialNwTribePriorityOverOwMinorBonus', () {
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 1.0,
        ),
        kDeclareWarColonialNwTribePriorityOverOwMinorBonus,
        reason:
            'nwAcquisitionWeight = 1.0 must produce the legacy '
            'kDeclareWarColonialNwTribePriorityOverOwMinorBonus '
            '($kDeclareWarColonialNwTribePriorityOverOwMinorBonus) '
            'exactly.',
      );
    });

    test('nwAcquisitionWeight = 0.0 returns 0 for both addends '
        '(legacy colonialPressure = false equivalent / regression guard)', () {
      // At zero NW priority neither addend may apply so a future
      // refactor that mis-routes the weight read and applies a non-zero
      // bonus under zero weight surfaces here.
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 0.0),
        0,
        reason:
            'nwAcquisitionWeight = 0.0 must return 0 so the NW-tribe '
            'dominance addend does not bias declare-war scoring (legacy '
            'colonialPressure = false equivalent).',
      );
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 0.0,
        ),
        0,
        reason:
            'nwAcquisitionWeight = 0.0 must return 0 for the '
            'priority-over-OW-minor addend.',
      );
    });

    test('early-sprint default curve weight (0.05) collapses both addends to a '
        'token nudge (5 / 18) so the OW conquest sprint stays dominant', () {
      // The gp1/gp2 +6 OW baseline is preserved by construction: at the
      // OW <= 7 early-sprint plateau the NW-tribe addends are negligible
      // versus the OW-minor / GP-blocker declare-war bonuses.
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 0.05),
        (kDeclareWarColonialNwTribeDominanceBonus * 0.05).round(),
        reason:
            'round(${kDeclareWarColonialNwTribeDominanceBonus} × 0.05) = '
            '${(kDeclareWarColonialNwTribeDominanceBonus * 0.05).round()}.',
      );
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 0.05,
        ),
        (kDeclareWarColonialNwTribePriorityOverOwMinorBonus * 0.05).round(),
        reason:
            'round(${kDeclareWarColonialNwTribePriorityOverOwMinorBonus} '
            '× 0.05) = '
            '${(kDeclareWarColonialNwTribePriorityOverOwMinorBonus * 0.05).round()}.',
      );
    });

    test('treasury-recovery override floor (0.60) scales both addends '
        'proportionally for locked GPs', () {
      // The § Resource-need treasury-recovery override lifts
      // newWorldAcquisition to kPhasePriorityNwTreasuryRecoveryFloor
      // (0.60); the NW-tribe addends must scale to 60% of their legacy
      // magnitudes, not snap to the full binary value.
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 0.6),
        (kDeclareWarColonialNwTribeDominanceBonus * 0.6).round(),
      );
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 0.6,
        ),
        (kDeclareWarColonialNwTribePriorityOverOwMinorBonus * 0.6).round(),
      );
    });

    test('intermediate weight (0.5) scales linearly (continuous curve)', () {
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 0.5),
        (kDeclareWarColonialNwTribeDominanceBonus * 0.5).round(),
      );
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 0.5,
        ),
        (kDeclareWarColonialNwTribePriorityOverOwMinorBonus * 0.5).round(),
      );
    });

    test('out-of-range weights clamp (> 1.0 -> 1.0, < 0.0 -> 0.0)', () {
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 1.5),
        kDeclareWarColonialNwTribeDominanceBonus,
        reason: 'weights above 1.0 clamp to the full-weight magnitude.',
      );
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 1.5,
        ),
        kDeclareWarColonialNwTribePriorityOverOwMinorBonus,
      );
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: -0.5),
        0,
        reason: 'negative weights clamp to 0 (no bonus applied).',
      );
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: -0.5,
        ),
        0,
      );
    });

    test('helpers are deterministic for identical inputs', () {
      expect(
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 0.4),
        declareWarColonialNwTribeDominanceBonus(nwAcquisitionWeight: 0.4),
      );
      expect(
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 0.4,
        ),
        declareWarColonialNwTribePriorityOverOwMinorBonus(
          nwAcquisitionWeight: 0.4,
        ),
      );
    });
  });
}
