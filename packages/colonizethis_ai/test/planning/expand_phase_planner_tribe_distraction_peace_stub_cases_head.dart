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

void registerExpandTribeDistractionPeaceStubHeadCases() {
  group('diplomacy_planner_peace_targets stub delegation equality scan', () {
    test(
      'stalledFutileGpPeaceTargets stub mirrors canonical across fixtures',
      () {
        const minor1Pid = 'oldWorld|${_minor1}_active';
        const rivalAPid = 'oldWorld|${_gpRivalA}_blocker';
        final fixtures = <({String name, Game game, AIWorldSnapshot snapshot})>[
          (
            name: 'fire path, futile GP and active GP blocker',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {
                _gpRivalA: [rivalAPid],
                _gpRivalB: [],
              },
              minorOwProvincesByMinorId: const {
                _minor1: [minor1Pid],
              },
              atWarFactionIds: const [_gpRivalA, _gpRivalB],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalB, _gpRivalA],
              invadableProvinceIdsSorted: const [minor1Pid, rivalAPid],
            ),
          ),
          (
            name: 'above-quota guard',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverConquestMinOwProvincesPerGp,
              gpRivalProvincesById: const {_gpRivalA: []},
              minorOwProvincesByMinorId: const {
                _minor1: ['oldWorld|${_minor1}_active'],
              },
              atWarFactionIds: const [_gpRivalA],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
              atWarWith: const [_gpRivalA],
              invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_active'],
            ),
          ),
          (
            name: 'empty invadable guard',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {_gpRivalA: []},
              atWarFactionIds: const [_gpRivalA],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalA],
              invadableProvinceIdsSorted: const [],
            ),
          ),
          (
            name: 'GP-only invadable guard (no minor on frontier)',
            game: buildStalledFutileExpandPeaceGame(
              ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
              gpRivalProvincesById: const {
                _gpRivalA: [rivalAPid],
                _gpRivalB: [],
              },
              atWarFactionIds: const [_gpRivalA, _gpRivalB],
            ),
            snapshot: ownSnapshot(
              oldWorldProvincesOwned:
                  kObserverDefaultStartOldWorldProvincesPerGp,
              atWarWith: const [_gpRivalA, _gpRivalB],
              invadableProvinceIdsSorted: const [rivalAPid],
            ),
          ),
        ];
        for (final fx in fixtures) {
          final canonical = stalledFutileGpPeaceTargets(
            game: fx.game,
            snapshot: fx.snapshot,
          );
          final stub = diplomacy_peace_targets.stalledFutileGpPeaceTargets(
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
      },
    );

  });
}
