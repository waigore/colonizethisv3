// Zero-regiment GP stalemate stub pins (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpEnemy = 'gp_enemy';
const String _gpThird = 'gp_third';
const String _minor1 = 'minor1';
const String _tribe1 = 'tribe1';

void
registerExpandPhasePlannerZeroRegimentGpStalemateStubMutualStalemateFireCases() {
  group(
    'mutualZeroRegimentGpStalematePeaceTargets — canonical firing path',
    () {
      test('mutualZeroRegimentGpStalematePeaceTargets is byte-equivalent '
          'across two consecutive invocations on the same inputs', () {
        final game = buildZeroRegimentExpandPeaceGame(
          ownProvinces: 7,
          ownRegimentCount: 0,
          enemyGpIds: const [_gpEnemy],
          enemyRegimentCount: 0,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 7,
          atWarWith: const [_gpEnemy],
        );
        final first = mutualZeroRegimentGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = mutualZeroRegimentGpStalematePeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(second, first);
      });
    },
  );
}
