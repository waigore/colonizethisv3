// Case bodies for `expand_phase_planner_stalled_futile_gp_and_tribe_distraction_peace_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.




import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRivalA = 'gp_rival_a';
const String _gpRivalB = 'gp_rival_b';
const String _minor1 = 'minor1';
const String _tribeA = 'tribe_a';
const String _tribeB = 'tribe_b';

void registerExpandTribeDistractionPeaceStubTailCases() {
  group('diplomacy_planner_peace_targets stub delegation equality scan', () {
    test('atWarGpDistractionTribePeaceTargets stub mirrors canonical '
        'across fixtures', () {
      final fixtures = <({String name, Game game, AIWorldSnapshot snapshot})>[
        (
          name: 'fire path, two tribes plus GP front',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA, _tribeB],
            atWarFactionIds: const [_gpRivalA, _tribeA, _tribeB],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_tribeB, _tribeA, _gpRivalA],
          ),
        ),
        (
          name: 'above-quota guard',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverConquestMinOwProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_gpRivalA, _tribeA],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            atWarWith: const [_gpRivalA, _tribeA],
          ),
        ),
        (
          name: 'no-GP-front guard (tribe-only war)',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_tribeA],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_tribeA],
          ),
        ),
        (
          name: 'GP-only war (no tribe in atWarWith)',
          game: buildStalledFutileExpandPeaceGame(
            ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
            gpRivalProvincesById: const {_gpRivalA: []},
            tribeIds: const [_tribeA],
            atWarFactionIds: const [_gpRivalA],
          ),
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
            atWarWith: const [_gpRivalA],
          ),
        ),
      ];
      for (final fx in fixtures) {
        final canonical = atWarGpDistractionTribePeaceTargets(
          game: fx.game,
          snapshot: fx.snapshot,
        );
        final stub = diplomacy_peace_targets
            .atWarGpDistractionTribePeaceTargets(
              game: fx.game,
              snapshot: fx.snapshot,
            );
        expect(
          stub,
          canonical,
          reason:
              'Delegating stub must mirror the canonical helper for '
              'fixture "${fx.name}".',
        );
      }
    });
  });
}
