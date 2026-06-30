// Tests for the additive civilian build scoring branch in `pickBuildOrder`
// (Refs #3793, SPEC/ai/civilian-build-planner.md § Scoring model). Civilian
// candidates are scored by `civilianBuildCandidateScore` (min-cap hard floor,
// replacement-urgency soft pull) and excluded at/above `maxCount`; the branch
// is additive — military/naval scoring is unchanged (AC10).
import 'package:colonizethis_ai/src/planning/build_planner.dart';
import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/planner_test_helpers.dart';

const _builder = BuildUnitOrder(
  unitType: kUnitTypeBuilder,
  isMilitary: false,
  spawnProvinceId: 'oldWorld|p1',
);
const _grenadiers = BuildUnitOrder(
  unitType: 'grenadiers',
  isMilitary: true,
  spawnProvinceId: 'oldWorld|p1',
);
const _sloop = BuildUnitOrder(
  unitType: 'sloop',
  isMilitary: false,
  spawnProvinceId: 'oldWorld|p1',
);

Game _game() => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: const [
    Player(
      id: 'gp1',
      displayName: 'France',
      isHuman: false,
      leaderKey: 'napoleon',
    ),
  ],
);

const _config = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'warmonger',
);
const _topology = MapTopology(nodes: [], edges: []);

BuildUnitOrder? _pick({
  required List<BuildUnitOrder> candidates,
  CivilianBuildScoringInput? civilianScoring,
  int turnSeed = 1,
  StrategicGoal goal = StrategicGoal.expand,
  // Default above the observer conquest quota so no stalled-expansion regiment
  // bonus inflates the military baseline — keeps the civilian/regiment score
  // contrast clean for the scoring-branch assertions.
  int oldWorldProvincesOwned = 31,
}) {
  final ctx = buildTestPlannerContext(
    game: _game(),
    topology: _topology,
    config: _config,
    primaryGoal: goal,
    turnSeed: turnSeed,
  );
  return pickBuildOrder(
    ctx: ctx,
    input: BuildPickInput(
      buildCandidates: candidates,
      cargoPreference: CargoPreference.none,
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      civilianScoring: civilianScoring,
    ),
  );
}

void main() {
  group('pickBuildOrder civilian scoring (Refs #3793)', () {
    test('AC3: below-min-cap civilian dominates the weighted pool over a '
        'regiment across seeds', () {
      // Builder count 0 < minBuilders 2 → min-cap boost (50.0) vs regiment ~1.
      var builderWins = 0;
      const trials = 40;
      for (var seed = 1; seed <= trials; seed++) {
        final chosen = _pick(
          candidates: const [_builder, _grenadiers],
          civilianScoring: const CivilianBuildScoringInput(
            currentCountByType: {kUnitTypeBuilder: 0},
          ),
          turnSeed: seed,
        );
        if (chosen?.unitType == kUnitTypeBuilder) builderWins++;
      }
      // The min-cap boost (50.0) vastly outweighs the regiment baseline, so it
      // dominates the deterministic weighted selection across seeds. (Selection
      // is deterministic per seed; the count is stable run-to-run.)
      expect(builderWins, greaterThanOrEqualTo((trials * 0.75).round()));
    });

    test('AC2: a civilian at its targetCount keeps the neutral base score and '
        'remains selectable in the pool', () {
      // Builder at targetCount 2 → neutral base score 1.0 (same footing as a
      // baseline regiment). Across seeds both candidates are selected at least
      // once, proving the civilian is in the weighted pool, not excluded.
      final selected = <String>{};
      for (var seed = 1; seed <= 40; seed++) {
        final chosen = _pick(
          candidates: const [_builder, _grenadiers],
          civilianScoring: const CivilianBuildScoringInput(
            currentCountByType: {kUnitTypeBuilder: 2},
          ),
          turnSeed: seed,
        );
        if (chosen != null) selected.add(chosen.unitType);
      }
      expect(selected, contains(kUnitTypeBuilder));
    });

    test('ACMax: a civilian at its maxCount is excluded from the pool', () {
      // Builder at maxCount 6 is dropped, leaving only the regiment — selection
      // is deterministic regardless of seed.
      for (var seed = 1; seed <= 5; seed++) {
        final chosen = _pick(
          candidates: const [_builder, _grenadiers],
          civilianScoring: const CivilianBuildScoringInput(
            currentCountByType: {kUnitTypeBuilder: 6},
          ),
          turnSeed: seed,
        );
        expect(chosen?.unitType, 'grenadiers');
      }
    });

    test('ACMax: all candidates excluded yields null', () {
      final chosen = _pick(
        candidates: const [_builder],
        civilianScoring: const CivilianBuildScoringInput(
          currentCountByType: {kUnitTypeBuilder: 6},
        ),
      );
      expect(chosen, isNull);
    });

    test('AC10: military/naval selection is identical with vs without civilian '
        'scoring input across seeds', () {
      for (var seed = 1; seed <= 25; seed++) {
        final withInput = _pick(
          candidates: const [_grenadiers, _sloop],
          civilianScoring: const CivilianBuildScoringInput(
            currentCountByType: {kUnitTypeBuilder: 0},
          ),
          turnSeed: seed,
        );
        final without = _pick(
          candidates: const [_grenadiers, _sloop],
          turnSeed: seed,
        );
        expect(withInput?.unitType, without?.unitType);
      }
    });

    test('civilian candidate with no scoring input keeps the neutral base '
        'score (branch inert)', () {
      // Without a CivilianBuildScoringInput the civilian is neither boosted nor
      // excluded; both candidates remain selectable.
      final selected = <String>{};
      for (var seed = 1; seed <= 40; seed++) {
        final chosen = _pick(
          candidates: const [_builder, _grenadiers],
          turnSeed: seed,
        );
        if (chosen != null) selected.add(chosen.unitType);
      }
      expect(selected, contains(kUnitTypeBuilder));
      expect(selected, contains('grenadiers'));
    });
  });
}
