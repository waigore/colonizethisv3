// Pins the **presence-guard** and **hit-testable tap** behaviour of
// `e2eTapCivilianWorkOrderLabel` in
// `app/integration_test/e2e_test_shared.dart`. The helper replaces the bare
// `tester.tap(find.text(workOrderLabel))` calls in
// `new_game_full_turn_e2e_test.dart` that previously sat between the
// `tap-Assign` step and the work-tile pick: those raw taps did not honour
// the e2e-ui-stability `verify visibility before interaction` rule and
// could silently drop the tap when the chosen work-order row was rendered
// just below the visible area on smaller surfaces.
//
// A regression here would either:
//
//   - silently no-op when the work-order label is not actually mounted
//     (helper proceeds to the downstream work-tile pick on a stale work
//     menu; full-turn scenario then burns the work-tile appear timeout),
//     or
//   - issue a tap on a non-hit-testable Text widget (Flutter tester
//     accepts the tap target but no listener fires; the work menu stays
//     mounted and the subsequent close-bottom-sheet helper races against
//     a still-open work menu).
//
// `integration_test/` runs behind a no-op `app_e2e_linux` lane today
// (`SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
// layer is the only per-PR enforcement gate for the helper's
// presence-guard and hit-testable-tap contracts.
//
// Refs GitHub #2336 AC1 (shared helpers) / AC2 (single canonical
// implementation) / AC10 (no silent flakiness from off-screen-trigger
// drops); `colonizethis-e2e-ui-stability.mdc` *verify visibility before
// interaction*.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

/// Mutable tap counter held outside the [StatelessWidget] harness so the
/// `must_be_immutable` lint stays satisfied (matches the
/// `e2e_ensure_visible_and_tap_hit_testable_test.dart` sibling).
class _TapCounter {
  int value = 0;
}

/// Synthetic civilian work-menu fixture. The fixture builds the labels
/// inside a [GestureDetector] (mirrors the production [InkWell]/`onTap`
/// shape exposed by the work-menu list tiles) so a successful
/// `ensureVisible + hitTestable` tap path increments the counter while an
/// off-screen drop leaves it at zero.
Widget _buildWorkMenuFixture({
  required List<String> labels,
  required _TapCounter taps,
  String? counterTargetLabel,
  bool ignorePointer = false,
  double topSpacer = 0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            if (topSpacer > 0) SizedBox(height: topSpacer),
            for (final label in labels)
              IgnorePointer(
                ignoring: ignorePointer,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (counterTargetLabel == null ||
                        label == counterTargetLabel) {
                      taps.value += 1;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(label),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'taps the requested work-order label when present and hit-testable',
    (WidgetTester tester) async {
      // Positive happy path: the work menu hosts Build improvement /
      // Prospect / Explore — the helper must resolve and tap exactly the
      // requested label (no fallback to the first sibling).
      final taps = _TapCounter();
      await tester.pumpWidget(
        _buildWorkMenuFixture(
          labels: const <String>['Build improvement', 'Prospect', 'Explore'],
          taps: taps,
          counterTargetLabel: 'Prospect',
        ),
      );

      await tapCivilianWorkOrderLabel(tester, 'Prospect');

      expect(
        taps.value,
        1,
        reason:
            'Helper must tap exactly the requested work-order label so the '
            'downstream work-tile pick selects the matching tile for the '
            'production scaffold (a fallback to the first sibling would '
            'silently fire the wrong work order on Builder rows that also '
            'render Prospect / Explore beside Build improvement).',
      );
    },
  );

  testWidgets(
    'fails fast with TestFailure when the requested label is not mounted',
    (WidgetTester tester) async {
      // The work menu mounted Build improvement / Explore but not the
      // requested Prospect — the helper's `expect(findsWidgets)` guard
      // must surface a TestFailure rather than silently proceeding to the
      // downstream work-tile pick on a stale menu (which would burn the
      // appear-timeout against a not-yet-rendered work order).
      final taps = _TapCounter();
      await tester.pumpWidget(
        _buildWorkMenuFixture(
          labels: const <String>['Build improvement', 'Explore'],
          taps: taps,
        ),
      );

      Object? caught;
      try {
        await tapCivilianWorkOrderLabel(tester, 'Prospect');
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'A missing work-order label must surface a TestFailure so the '
            'surrounding full-turn scenario fails at the offending step '
            'rather than burning the AC9 wall-clock budget on a stale '
            'work menu.',
      );
      expect(
        taps.value,
        0,
        reason:
            'Helper must not fall back to tapping any sibling label when '
            'its presence guard fires; a silent fallback would mutate '
            'panel state on the wrong work order.',
      );
    },
  );

  testWidgets(
    'fails fast with TestFailure on an empty work-menu fixture',
    (WidgetTester tester) async {
      // No work-order labels at all (work menu never mounted) — same
      // contract as the missing-specific-label test but pins the
      // zero-mount edge case so a future refactor that swaps
      // `findsWidgets` for `findsOneWidget` does not silently weaken
      // the guard to a less obvious failure path.
      final taps = _TapCounter();
      await tester.pumpWidget(
        _buildWorkMenuFixture(labels: const <String>[], taps: taps),
      );

      Object? caught;
      try {
        await tapCivilianWorkOrderLabel(tester, 'Build improvement');
      } catch (e) {
        caught = e;
      }

      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'When no work-order label is mounted, the helper must surface '
            'a TestFailure (the same fail-fast contract documented on '
            'e2eTapFirstAssignInCivilianPanel).',
      );
      expect(
        taps.value,
        0,
        reason:
            'Empty-fixture case: helper must not have tapped anything.',
      );
    },
  );

  testWidgets(
    'taps the canonical hit-testable element when multiple matches exist',
    (WidgetTester tester) async {
      // Two siblings render the same `Build improvement` label (mirrors a
      // builder/merchant pair that both expose the label in the work
      // menu). The helper delegates to
      // `e2eEnsureVisibleAndTapHitTestable`, which picks the first
      // hit-testable element via `.first`. The pin guards against a
      // regression that switched to `tester.tap(label)` directly — that
      // path would throw on the multi-element ambiguity instead of
      // resolving deterministically.
      final taps = _TapCounter();
      await tester.pumpWidget(
        _buildWorkMenuFixture(
          labels: const <String>['Build improvement', 'Build improvement'],
          taps: taps,
        ),
      );

      await tapCivilianWorkOrderLabel(tester, 'Build improvement');

      expect(
        taps.value,
        1,
        reason:
            'Helper must resolve the first hit-testable match and fire '
            'exactly one tap rather than throwing on the multi-element '
            'finder (a regression that swapped the helper for the raw '
            'tap path would either throw or fire two taps).',
      );
    },
  );

  testWidgets(
    'scrolls an off-screen label into view before tapping',
    (WidgetTester tester) async {
      // The requested label is rendered far below the visible area; the
      // helper must rely on `e2eEnsureVisibleAndTapHitTestable` to
      // best-effort scroll the label into view before the tap. A
      // regression that dropped the `ensureVisible` call would either
      // miss the tap (no counter increment) on Linux headless CI.
      final taps = _TapCounter();
      await tester.pumpWidget(
        _buildWorkMenuFixture(
          labels: const <String>['Build improvement', 'Prospect'],
          taps: taps,
          counterTargetLabel: 'Prospect',
          topSpacer: 3000,
        ),
      );

      await tapCivilianWorkOrderLabel(tester, 'Prospect');

      expect(
        taps.value,
        1,
        reason:
            'Helper must scroll the off-screen label into view before '
            'tapping (the e2e-ui-stability rule: verify visibility before '
            'interaction). A regression that dropped ensureVisible would '
            'silently drop the tap on a small surface.',
      );
    },
  );
}
