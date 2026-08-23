// Behavioural integration pins for the Phase 3 soft-weight wiring of the
// economy build-pipeline cargo bonus (Refs #2847; renamed off the
// `*soft_weight_wiring_test.dart` family in Refs #3749 § Test streamlining
// because this is a `pickBuildOrder` behavioural pin, not the parameterized
// `scaleWeightedBonus` contract).
//
// Mirrors `phase_planner_goal_filter_colonial_pressure_test.dart` and
// `phase_planner_diplomacy_declare_war_nw_suppression_test.dart` for
// the build-pipeline cargo-bonus migration. Pins the contract of the
// new optional `BuildPickInput.colonialPressureWeight` slot:
//
//   - When `colonialPressureWeight == 1.0`, `pickBuildOrder` produces
//     the legacy `colonialPressure: true` cargo-bonus path exactly.
//     This is the identity-equal anchor that future refactors must not
//     weaken.
//
//   - When `colonialPressureWeight == 0.0`, `pickBuildOrder` produces
//     the legacy `colonialPressure: false` path exactly — the weight
//     gates the bonus off regardless of the legacy boolean. This is
//     the regression guard a future refactor that misroutes the
//     weight read must surface as a non-zero cargo bonus.
//
//   - When `colonialPressureWeight` is between the endpoints, the
//     cargo bonus scales linearly with the weight. This pin uses a
//     candidate set where the cargo bonus tips the weighted-random
//     selection so a behavioural difference between the endpoints is
//     observable.
//
//   - When `colonialPressureWeight == null`, the legacy boolean path
//     keyed off `BuildPickInput.colonialPressure` runs unchanged
//     (callers that omit the weight keep pre-Phase-3 behaviour).
//
// The boolean Phase 2 resolver
// (`resolvePhaseEconomyColonialPressureActive`) and weight resolver
// (`resolvePhaseEconomyColonialPressureWeight`) remain pinned by
// `phase_planner_economy_filter_test.dart` and
// `phase_planner_priority_weight_resolvers_test.dart` respectively.
// This file targets only the build-pipeline consumer that the Phase 3
// slice migrated from the legacy boolean to the optional weight.

import 'package:colonizethis_ai/src/planning/build_planner.dart';
import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/phase_planner_economy_build_pick_cargo_bonus_test_support.dart';
import '../support/planner_test_helpers.dart';
import 'phase_planner_economy_build_pick_cargo_bonus_tail_cases.dart';

// Candidate fixture: one cargo-capable ship (galleon, cargoHold = 6)
// and one regiment (grenadiers). Same `spawnProvinceId` so the
// build-pipeline scoring difference is driven only by the cargo
// bonus / military bonus deltas — no positional bias.
const List<BuildUnitOrder> _galleonAndGrenadiersCandidates = [
  BuildUnitOrder(
    unitType: 'galleon',
    isMilitary: false,
    spawnProvinceId: 'oldWorld|p1',
  ),
  BuildUnitOrder(
    unitType: 'grenadiers',
    isMilitary: true,
    spawnProvinceId: 'oldWorld|p1',
  ),
];

const AIConfig _config = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

// `primaryGoal = StrategicGoal.conquer` + `provincesToVictory = 14`
// (above `kBuildRegimentVictoryPaceThreshold = 10`) bumps the
// grenadier's military bonus to `max(0, 1.0) + 1.5 = 2.5`, sitting the
// regiment's total score between the ship's no-cargo-bonus and
// full-cargo-bonus values (1.8 vs 4.3 for the `henry` personality).
// The weighted-random selection therefore visibly biases toward
// regiment without cargo bonus and toward the cargo ship with full
// bonus — making the cargo-bonus pathway observable through the
// chosen unit type.
//
// `oldWorldProvincesOwned = kObserverConquestMinOwProvincesPerGp = 10`
// keeps `isObserverConquestExpansionPressure` `false` so neither the
// "regiments-only" candidate filter nor the stalled-expansion
// regiment bonus fire — the score delta between cargo-on and
// cargo-off is the only differentiator.
BuildUnitOrder? _pick({
  required bool colonialPressure,
  double? colonialPressureWeight,
  int turnSeed = 7,
  StrategicGoal primaryGoal = StrategicGoal.conquer,
  int provincesToVictory = 14,
  int oldWorldProvincesOwned = kObserverConquestMinOwProvincesPerGp,
}) {
  final ctx = buildTestPlannerContext(
    game: phasePlannerEconomyBuildPickCargoBonusGame(),
    topology: const MapTopology(nodes: [], edges: []),
    config: _config,
    primaryGoal: primaryGoal,
    turnSeed: turnSeed,
  );
  return pickBuildOrder(
    ctx: ctx,
    input: BuildPickInput(
      buildCandidates: _galleonAndGrenadiersCandidates,
      cargoPreference: CargoPreference.none,
      provincesToVictory: provincesToVictory,
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      colonialPressure: colonialPressure,
      colonialPressureWeight: colonialPressureWeight,
    ),
  );
}

void main() {
  group('Phase 3 economy build-pick soft-weight wiring (Refs #2847)', () {
    test(
      'colonialPressureWeight = 1.0 identity-equal to legacy '
      'colonialPressure = true (full-weight anchor)',
      () {
        // The Phase 3 contract: at full weight the cargo bonus must
        // match the legacy hard-phase path exactly. Two pickBuildOrder
        // calls that differ only in (colonialPressure=true, weight=null)
        // vs (colonialPressure=false, weight=1.0) must produce the same
        // chosen unit because the cargo-bonus magnitude is identical
        // (+2.5 in both branches) and the weighted-random pick is
        // seeded deterministically.
        final legacyOn = _pick(colonialPressure: true);
        final weightOne = _pick(
          colonialPressure: false,
          colonialPressureWeight: 1.0,
        );
        expect(
          weightOne?.unitType,
          legacyOn?.unitType,
          reason:
              'colonialPressureWeight = 1.0 must produce the same selection '
              'as the legacy colonialPressure = true path '
              '(both add +2.5 cargo bonus to cargo-capable ships).',
        );
      },
    );

    test(
      'colonialPressureWeight = 0.0 identity-equal to legacy '
      'colonialPressure = false (zero-weight anchor / regression guard)',
      () {
        // The Phase 3 contract: at zero weight the cargo bonus must be
        // gated off so a future refactor that mis-routes the weight
        // read surfaces a non-zero cargo bonus that diverges from the
        // legacy `colonialPressure = false` selection.
        final legacyOff = _pick(colonialPressure: false);
        final weightZero = _pick(
          colonialPressure: true,
          colonialPressureWeight: 0.0,
        );
        expect(
          weightZero?.unitType,
          legacyOff?.unitType,
          reason:
              'colonialPressureWeight = 0.0 must produce the same selection '
              'as the legacy colonialPressure = false path '
              '(the weight gate is the production source of truth and '
              'overrides the legacy boolean when supplied).',
        );
      },
    );

    test(
      'weight gate causes a statistical bias toward cargo ships '
      '(cargo bonus magnitude actually changes the weighted selection)',
      () {
        // Sanity pin: at full weight (`colonialPressureWeight = 1.0`)
        // the cargo bonus must bias the weighted-random selection
        // toward the cargo ship strictly more often than at zero
        // weight, otherwise the identity-equality pins above would be
        // vacuously satisfied (the cargo bonus would not actually
        // influence the build pipeline).
        //
        // The candidate fixture has ship score = 1.8 (no cargo bonus)
        // vs regiment score = 3.8 under conquer + provincesToVictory
        // 14, so without cargo bonus the regiment dominates the
        // weighted selection. Full cargo bonus raises the ship to 4.3,
        // overtaking the regiment. The selection bias must therefore
        // flip between the endpoints across a representative sample
        // of turn seeds.
        var shipsAtZero = 0;
        var shipsAtFullWeight = 0;
        for (var seed = 0; seed < 50; seed++) {
          final pickZero = _pick(
            colonialPressure: false,
            colonialPressureWeight: 0.0,
            turnSeed: seed,
          );
          if (pickZero?.unitType == 'galleon') shipsAtZero++;
          final pickFull = _pick(
            colonialPressure: false,
            colonialPressureWeight: 1.0,
            turnSeed: seed,
          );
          if (pickFull?.unitType == 'galleon') shipsAtFullWeight++;
        }
        expect(
          shipsAtFullWeight,
          greaterThan(shipsAtZero),
          reason:
              'Full colonialPressureWeight (1.0) must bias the weighted '
              'selection toward the cargo ship strictly more often than '
              'zero weight (0.0) — the cargo bonus magnitude must be a '
              'non-zero contribution to candidate scoring. Sampled '
              'across 50 seeds, ships-at-zero = $shipsAtZero, '
              'ships-at-full = $shipsAtFullWeight.',
        );
      },
    );

    test(
      'null colonialPressureWeight preserves the legacy colonialPressure = true '
      'path (legacy-fallback / null-weight pin)',
      () {
        // Pre-Phase-3 path: when no weight is supplied the build
        // pipeline must use the legacy boolean exactly as before. This
        // pin guards against an accidental migration that requires a
        // non-null weight to activate the cargo bonus.
        final nullWeightOn = _pick(
          colonialPressure: true,
          colonialPressureWeight: null,
        );
        final weightOne = _pick(
          colonialPressure: true,
          colonialPressureWeight: 1.0,
        );
        expect(
          nullWeightOn?.unitType,
          weightOne?.unitType,
          reason:
              'Null weight + colonialPressure = true must match weight = 1.0 '
              '(the null-weight fallback path applies +2.5 cargo bonus to '
              'cargo-capable ships exactly as the full-weight path does).',
        );
      },
    );
  });

  registerPhasePlannerEconomyBuildPickCargoBonusTailCases();
}
