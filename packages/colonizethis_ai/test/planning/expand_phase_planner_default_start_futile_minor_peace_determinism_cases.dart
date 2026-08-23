// Case bodies for `expand_phase_planner_default_start_futile_minor_peace_test.dart` (Refs #4602 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

const String _gpOwn = 'gp_own';
const String _gpRival = 'gp_rival';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';

void registerDefaultStartFutileMinorPeaceDeterminismCases() {
  group('defaultStartFutileMinorPeaceTargets — determinism', () {
    test('returns identical lists across three consecutive calls', () {
      // Must-have #7: pure-function determinism. The decider has two
      // arms and a sort; the same `(Game, AIWorldSnapshot)` inputs must
      // always yield the same `List<String>`.
      const minor1InvadablePid = 'oldWorld|${_minor1}_1';
      final game = buildDefaultStartFutileMinorExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorOwProvincesByMinorId: const {
          _minor1: [minor1InvadablePid],
          _minor2: [],
        },
        atWarMinorIds: const [_minor1, _minor2],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [_minor1, _minor2],
        invadableProvinceIdsSorted: const [minor1InvadablePid],
      );
      final first = defaultStartFutileMinorPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = defaultStartFutileMinorPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final third = defaultStartFutileMinorPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(
        first,
        const [_minor2],
        reason:
            'Canonical decider must return only the futile minor across '
            'every invocation.',
      );
      expect(
        second,
        first,
        reason:
            'Must-have #7: identical inputs must always yield identical '
            'lists (call 2 vs call 1).',
      );
      expect(
        third,
        first,
        reason:
            'Must-have #7: identical inputs must always yield identical '
            'lists (call 3 vs call 1).',
      );
    });
  });
}
