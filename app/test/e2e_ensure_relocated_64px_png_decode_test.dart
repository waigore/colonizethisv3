/// Pins the **success**, **count-mismatch**, and **ordered-mismatch**
/// branches of `e2eEnsureRelocated64pxPngDecode`
/// (`app/integration_test/e2e_test_shared_bootstrap.dart`) so the warm-cache
/// pre-decode that every new-game E2E scenario runs through
/// `e2eEnsureAllRelocated64pxPngsLoad` /
/// `e2eEnsureAllRelocated64pxPngsLoadSuiteOnce` cannot regress silently
/// (Refs GitHub #2336 AC3 / `SPEC/program/e2e-integration-tests.md` §
/// Relocated 64px map icon preload).
///
/// The helper is the **single gate** that protects every new-game
/// integration test against drift between the `assets/icons/64/` manifest
/// and the `kCivilianIconSlugs` / `kResourceIconIds` / `kTownIconIds` /
/// `kProvinceLabelIconIds` source-of-truth lists. A silent regression in
/// any of:
///
/// 1. the **success path** (matching expected set returns without
///    failure),
/// 2. the **count-mismatch fail** path (different expected vs manifest
///    sizes raise a [TestFailure] before any decode happens),
/// 3. the **ordered-mismatch fail** path (same size but different entries
///    raises a [TestFailure] before any decode happens),
/// 4. and the **custom-reason overrides** for both fail paths
///    (so a maintainer-supplied `countMismatchReason` /
///    `orderedMismatchReason` is actually surfaced in CI logs),
///
/// would shift from a loud preload assertion failure to a delayed decode
/// failure deep inside `e2eEnsureAllRelocated64pxPngsLoad` callers (or
/// worse, a silent pass that masks a missing icon family). That kind of
/// regression is the exact wall-clock-burning surprise #2336 is trying to
/// eliminate, so the contract is pinned at the widget-unit layer rather
/// than relying on the integration suite (which runs behind a no-op
/// `app_e2e_linux` lane today — `SPEC/program/e2e-integration-tests.md`
/// § CI).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared_bootstrap.dart';

/// Builds a [Set] of the same size as [actual] containing only paths that
/// will not appear in the real `assets/icons/64/` manifest. Used to drive
/// the **ordered-mismatch** branch deterministically.
Set<String> _wrongSameCountExpected(List<String> actual) {
  return <String>{
    for (var i = 0; i < actual.length; i++)
      'assets/icons/64/_pin_test_nonexistent_$i.png',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  suppressLogsForTests();

  test(
    'success path returns without failure when expected set matches the manifest',
    () async {
      final actual = await e2eDiscoverRelocated64pxPngAssets();
      expect(
        actual,
        isNotEmpty,
        reason:
            'Real `assets/icons/64/` manifest must surface at least one '
            'PNG so the success path actually exercises the helper '
            '(empty manifest would short-circuit on the `isNotEmpty` '
            'assertion instead).',
      );
      await e2eEnsureRelocated64pxPngDecode(actual.toSet());
    },
  );

  test(
    'count mismatch raises a TestFailure with the manifest size in the default reason',
    () async {
      final actual = await e2eDiscoverRelocated64pxPngAssets();
      expect(actual, isNotEmpty);
      Object? caught;
      try {
        await e2eEnsureRelocated64pxPngDecode(const <String>{});
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Empty expected set must fail the count branch loudly so '
            'callers cannot accidentally skip the manifest gate (Refs '
            '#2336 AC3).',
      );
      final message = caught.toString();
      expect(
        message,
        contains('Unexpected number of relocated 64px PNG assets'),
        reason:
            'Default count-mismatch reason must call out the helper '
            'identity so CI logs are attributable without a follow-up '
            'manifest dump.',
      );
      expect(
        message,
        contains('Expected 0'),
        reason:
            'Default reason must echo the caller-supplied expected count '
            'so a maintainer can spot stale slug lists immediately.',
      );
      expect(
        message,
        contains('found ${actual.length}'),
        reason:
            'Default reason must echo the actual manifest count so the '
            'failure message disambiguates "extra slug" vs "missing '
            'manifest entry".',
      );
    },
  );

  test(
    'count mismatch surfaces a custom countMismatchReason in the failure message',
    () async {
      Object? caught;
      try {
        await e2eEnsureRelocated64pxPngDecode(
          const <String>{},
          countMismatchReason: 'PIN_COUNT_MISMATCH_REASON',
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Custom count-mismatch reason must still fail loudly; the '
            'override only replaces the reason text, never the assertion.',
      );
      expect(
        caught.toString(),
        contains('PIN_COUNT_MISMATCH_REASON'),
        reason:
            'Caller-supplied `countMismatchReason` must propagate into '
            'the `TestFailure` message so scenario-level callers (e.g. '
            '`new_game_full_turn_e2e_test`) keep their disambiguating '
            'context after a refactor.',
      );
    },
  );

  test(
    'ordered mismatch raises a TestFailure with the default reason when sizes match but entries differ',
    () async {
      final actual = await e2eDiscoverRelocated64pxPngAssets();
      expect(
        actual.length,
        greaterThan(1),
        reason:
            'Real manifest needs at least two PNGs so the synthetic '
            '"wrong same-count" expected set cannot accidentally equal '
            'the actual sorted list.',
      );
      final wrong = _wrongSameCountExpected(actual);
      Object? caught;
      try {
        await e2eEnsureRelocated64pxPngDecode(wrong);
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Same-count-but-wrong-content expected set must fail the '
            'ordered branch — otherwise a missing slug could be hidden '
            'by an unrelated extra slug of the same family.',
      );
      expect(
        caught.toString(),
        contains(
          'Relocated 64px PNG manifest entries do not match expected '
          'map icon families',
        ),
        reason:
            'Default ordered-mismatch reason must call out the helper '
            'identity so the failure is attributable in CI logs without '
            'extra grep work.',
      );
    },
  );

  test(
    'ordered mismatch surfaces a custom orderedMismatchReason in the failure message',
    () async {
      final actual = await e2eDiscoverRelocated64pxPngAssets();
      expect(actual.length, greaterThan(1));
      final wrong = _wrongSameCountExpected(actual);
      Object? caught;
      try {
        await e2eEnsureRelocated64pxPngDecode(
          wrong,
          orderedMismatchReason: 'PIN_ORDERED_MISMATCH_REASON',
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Custom ordered-mismatch reason must still fail loudly; the '
            'override only replaces the reason text, never the assertion.',
      );
      expect(
        caught.toString(),
        contains('PIN_ORDERED_MISMATCH_REASON'),
        reason:
            'Caller-supplied `orderedMismatchReason` must propagate into '
            'the `TestFailure` message so scenario-level callers keep '
            'their disambiguating context after a refactor.',
      );
    },
  );
}
