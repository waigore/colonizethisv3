import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart'
    show CivilianUnitRowCard;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

Future<void> e2eTapFirstAssignInCivilianPanel(WidgetTester tester) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final assign = find.descendant(of: root, matching: find.text('Assign'));
  expect(assign, findsWidgets);
  final firstAssign = assign.first;
  await tester.scrollUntilVisible(
    firstAssign,
    120,
    scrollable: panelScrollable,
  );
  final didTap = await e2eTapEnclosingNinePatchButtonOrLabel(
    tester,
    firstAssign,
  );
  expect(
    didTap,
    isTrue,
    reason:
        'First Assign in civilian panel resolved to zero elements after the '
        'findsWidgets guard passed; the downstream work-menu wait would race '
        'a not-yet-tapped Assign button.',
  );
  // Lifted post-tap work-menu wait: see [e2eAwaitCivilianWorkMenuMounted] for
  // the canonical label set and 5 s timeout. The default phase name preserves
  // the legacy inline `wait_until_civilian_work_menu` label byte-for-byte.
  // Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
  await e2eAwaitCivilianWorkMenuMounted(tester);
}

/// Taps a civilian work-order label (for example `Build improvement`,
/// `Prospect`, or `Explore`) inside the open civilian-panel work menu, using
/// [e2eEnsureVisibleAndTapHitTestable] so the tap fires from a canonical
/// hit-testable position even when the label is rendered slightly off-screen
/// by a transient overlay or a small surface.
///
/// Replaces the legacy raw `tester.tap(find.text(workOrderLabel))` taps in
/// `new_game_full_turn_e2e_test.dart` that ran right after
/// [e2eTapFirstAssignInCivilianPanel] / [e2eTapAssignOnCivilianRowWithTitle].
/// Those tap-Assign helpers only guarantee that *one* of
/// `{Build improvement, Prospect, Explore}` is hit-testable on return — the
/// **specific** label the caller wants may still be obscured (e.g. behind a
/// soft keyboard, a transient bottom sheet, or a viewport that needs scrolling)
/// at the instant of the tap. Wrapping the tap in this helper enforces the
/// e2e-ui-stability rule's *verify visibility before interaction* directive
/// at the same call sites that previously skipped it. Refs GitHub #2336 AC1 /
/// AC2 / AC10; `colonizethis-e2e-ui-stability.mdc`.
///
/// Contract:
///
/// - Throws [TestFailure] via [expect] when no `Text` widget matching
///   [workOrderLabel] is mounted at all, so the surrounding scenario fails
///   fast at the offending step rather than burning the downstream
///   work-tile timeout against an unmounted work menu (the same fail-fast
///   contract documented on [e2eTapFirstAssignInCivilianPanel]).
/// - Delegates to [e2eEnsureVisibleAndTapHitTestable], which best-effort
///   scrolls the label into view, prefers the `hitTestable()` resolution,
///   and falls back to the raw finder when no hit-testable element resolves
///   (the same path the panel-opener rail/marker taps already use).
/// - Throws [TestFailure] when [e2eEnsureVisibleAndTapHitTestable] reports
///   no tap was issued (zero-element resolution after the presence assertion
///   passes — only possible under unusual race conditions where the label
///   vanishes between the assertion and the resolve). This keeps the helper
///   sound for callers that rely on a tap actually firing before the
///   downstream work-tile pick begins.
Future<void> e2eTapCivilianWorkOrderLabel(
  WidgetTester tester,
  String workOrderLabel,
) async {
  final label = find.text(workOrderLabel);
  expect(
    label,
    findsWidgets,
    reason:
        'Civilian work-order label "$workOrderLabel" not found in the open '
        'work menu. Either the preceding Assign tap did not mount the work '
        'menu, or the label name has drifted from the production scaffold.',
  );
  final didTap = await e2eEnsureVisibleAndTapHitTestable(tester, label);
  expect(
    didTap,
    isTrue,
    reason:
        'Civilian work-order label "$workOrderLabel" was present but the '
        'shared ensureVisible/hit-testable tap path issued no tap; the '
        'downstream work-tile pick would race a not-yet-tapped label.',
  );
}

/// Taps **Assign** on the [CivilianUnitRowCard] whose title is exactly
/// [unitTypeTitle] (GitHub #2336 H9).
///
/// The civilian panel migrated its unit rows off Material `ListTile` to the
/// bespoke [CivilianUnitRowCard] (Refs #2914 S8); this helper therefore scopes
/// the per-row **Assign** lookup to that card so the row's `CtNinePatchButton`
/// resolves after the migration instead of silently matching nothing.
Future<void> e2eTapAssignOnCivilianRowWithTitle(
  WidgetTester tester,
  String unitTypeTitle,
) async {
  final root = find.byKey(kCtE2ECivilianPanelRootKey);
  final listView = find.descendant(of: root, matching: find.byType(ListView));
  expect(listView, findsOneWidget);
  final panelScrollable = find.descendant(
    of: listView,
    matching: find.byType(Scrollable),
  );
  expect(panelScrollable, findsOneWidget);
  final titlesInList = find.descendant(
    of: listView,
    matching: find.text(unitTypeTitle),
  );
  // The panel may still be mid entrance-animation; settle it on-screen before
  // dragging so gesture start points land inside the render view (#2336 AC6).
  await e2eWaitScrollableOnScreen(tester, panelScrollable);
  final sw = Stopwatch()..start();
  while (titlesInList.evaluate().isEmpty &&
      sw.elapsed < const Duration(seconds: 20)) {
    final dragged = await e2eDragScrollableFromVisiblePoint(
      tester,
      panelScrollable,
      const Offset(0, -120),
    );
    if (!dragged) {
      await e2eWaitScrollableOnScreen(tester, panelScrollable);
    }
    await e2ePumpUntilConditionOrIdle(
      tester,
      () => titlesInList.evaluate().isNotEmpty,
      timeout: const Duration(milliseconds: 200),
      phaseName: 'pump_until_civilian_title_visible_after_scroll_drag',
    );
  }
  expect(
    titlesInList,
    findsWidgets,
    reason:
        'Timed out scrolling civilian panel for a visible "$unitTypeTitle" row',
  );
  final n = titlesInList.evaluate().length;
  for (var i = 0; i < n; i++) {
    final titleAt = titlesInList.at(i);
    try {
      await tester.scrollUntilVisible(
        titleAt,
        120,
        scrollable: panelScrollable,
      );
    } catch (_) {}
    try {
      await tester.ensureVisible(titleAt);
    } catch (_) {}
    final rowCard = find.ancestor(
      of: titleAt,
      matching: find.byType(CivilianUnitRowCard),
    );
    final assign = find.descendant(of: rowCard, matching: find.text('Assign'));
    if (assign.evaluate().isEmpty) {
      continue;
    }
    final assignHit = assign.first;
    final didTap = await e2eTapEnclosingNinePatchButtonOrLabel(
      tester,
      assignHit,
    );
    expect(
      didTap,
      isTrue,
      reason:
          'Assign on civilian row "$unitTypeTitle" resolved to zero elements '
          'after the per-row Assign descendant guard passed; the downstream '
          'work-menu wait would race a not-yet-tapped Assign button.',
    );
    // Lifted post-tap work-menu wait: see [e2eAwaitCivilianWorkMenuMounted].
    // The legacy `wait_until_civilian_work_menu_row` phase label is preserved
    // explicitly so the title-scoped sibling helper stays distinguishable in
    // perf-timing dumps (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
    await e2eAwaitCivilianWorkMenuMounted(
      tester,
      phaseName: 'wait_until_civilian_work_menu_row',
    );
    return;
  }
  fail('No idle Assign row for unit type "$unitTypeTitle" in civilian panel');
}
