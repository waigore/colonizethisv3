import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

/// Ensures [trigger] is visible (best-effort) and taps its first
/// hit-testable element, falling back to the raw [trigger] when no
/// hit-testable element resolves.
///
/// Encodes the defensive rail/marker tap sequence shared by
/// [e2eOpenCivilianPanel], [e2eOpenNavalPanel], and [e2eOpenProductionPanel]
/// so each panel opener gains uniform off-screen-trigger resilience
/// (Refs GitHub #2336 AC1 / AC2 / AC10; PR #2555 history — the naval rail
/// tap could land off-target until `ensureVisible` + hit-testable resolve
/// was added inline, while the civilian opener kept the brittle raw-tap
/// path that drops the tap when the rail button is rendered but pushed
/// outside the viewport by a transient overlay).
///
/// Contract:
///
/// - When [trigger] resolves to zero elements, returns `false` without
///   tapping. The caller remains responsible for the upstream presence
///   check; the panel-opener `tryOpen` closures already gate on
///   `trigger.evaluate().isNotEmpty` before calling, so this no-op branch
///   is a safety net rather than the primary path.
/// - Calls [WidgetTester.ensureVisible] inside a `try`/`catch (_)` so an
///   `ensureVisible` failure (for example when the trigger is not in any
///   `Scrollable`) does not throw past the helper.
/// - Resolves the tap target via `trigger.hitTestable()`; falls back to
///   the raw [trigger] when no element is hit-testable so the tap still
///   fires from the same canonical position the legacy opener bodies
///   used.
/// - Taps the first resolved element with `warnIfMissed: false` to match
///   the existing panel-opener contract.
/// - Returns `true` when the tap was issued.
Future<bool> e2eEnsureVisibleAndTapHitTestable(
  WidgetTester tester,
  Finder trigger,
) async {
  if (trigger.evaluate().isEmpty) {
    return false;
  }
  try {
    await tester.ensureVisible(trigger);
  } catch (_) {}
  final hit = trigger.hitTestable();
  final target = hit.evaluate().isNotEmpty ? hit : trigger;
  await tester.tap(target.first, warnIfMissed: false);
  return true;
}

/// Awaits one of [primary] / [secondary] becoming hit-testable before the
/// outer panel-opener loop attempts a [e2eEnsureVisibleAndTapHitTestable]
/// tap, defending against transient overlays that cover the rail/marker
/// trigger.
///
/// Lifts the inline rail/marker hit-testable wait that the naval opener
/// has carried since PR #2555 (`wait_until_naval_rail_hit_testable` /
/// `wait_until_naval_marker_hit_testable` phases) into a single shared
/// primitive so [e2eOpenCivilianPanel], [e2eOpenNavalPanel], and
/// [e2eOpenProductionPanel] gain identical pre-tap settle semantics.
/// Before this lift, the civilian opener tapped a rail that might not be
/// hit-testable (relying on `e2eEnsureVisibleAndTapHitTestable`'s
/// best-effort scroll-into-view) and let the outer adaptive-poll loop
/// retry on miss; production took the same shape. The naval opener
/// instead waited up to 5 s for one of `[empireRailButton, markerButton]`
/// to become hit-testable before tapping. Refs GitHub #2336 AC1 / AC10
/// (deferred slice from PR #2782).
///
/// Contract:
///
/// - Short-circuits with no pump and no perf event when either [primary]
///   or [secondary] is already hit-testable. The fast-path keeps the
///   no-overlay common case at byte-equivalent cost vs the pre-#2555
///   civilian/production openers.
/// - Otherwise delegates to [e2eWaitUntilAnyFinderHitTestable] with the
///   provided [timeout] and [phaseName]. That helper polls with adaptive
///   backoff (25 → 500 ms cap) and emits `result=found{,_immediate,_at_
///   timeout}` / `result=timeout` perf timings on [perf]. On final
///   timeout it fails via [fail] with the same diagnostic message the
///   inline naval opener has surfaced since PR #2555 (`Timed out after
///   ${timeout.inSeconds}s waiting for any of ...`), so a regression that
///   left the trigger permanently obscured fails with a useful message
///   inside the inner wait rather than silently consuming the outer
///   opener loop's full budget.
/// - When [secondary] is `null`, only [primary] is polled (production
///   opener path — no `markerButton` concept).
Future<void> e2eAwaitPanelOpenerRailHitTestable(
  WidgetTester tester, {
  required Finder primary,
  Finder? secondary,
  Duration timeout = const Duration(seconds: 5),
  E2ePerfLog? perf,
  required String phaseName,
}) async {
  if (primary.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  if (secondary != null && secondary.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  final finders = <Finder>[primary, ?secondary];
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    finders,
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
}

/// Civilian work-menu labels surfaced after tapping an `Assign` button in
/// the civilian panel (`Build improvement`, `Prospect`, `Explore`).
///
/// Single source of truth consumed by [e2eAwaitCivilianWorkMenuMounted] (and
/// transitively by [e2eTapFirstAssignInCivilianPanel] and
/// [e2eTapAssignOnCivilianRowWithTitle]) so a label drift in production
/// surfaces in one place. Pinned by the widget test in
/// `app/test/e2e_await_civilian_work_menu_mounted_test.dart` to keep the
/// label set deterministic across SDK upgrades. Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 6.
const List<String> kE2eCivilianWorkMenuLabels = <String>[
  'Build improvement',
  'Prospect',
  'Explore',
];

/// Default timeout for [e2eAwaitCivilianWorkMenuMounted]. Matches the legacy
/// pre-lift inline `Duration(seconds: 5)` budget shared by
/// [e2eTapFirstAssignInCivilianPanel] and [e2eTapAssignOnCivilianRowWithTitle]
/// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
const Duration kE2eDefaultCivilianWorkMenuMountTimeout = Duration(seconds: 5);

/// Default phase label emitted by [e2eAwaitCivilianWorkMenuMounted] — matches
/// the legacy inline `wait_until_civilian_work_menu` phase used by
/// [e2eTapFirstAssignInCivilianPanel] before the lift. Callers tapping a
/// title-scoped `Assign` row pass `wait_until_civilian_work_menu_row` to
/// preserve the historical label split.
const String kE2eDefaultCivilianWorkMenuMountPhase =
    'wait_until_civilian_work_menu';

/// Polls until any civilian work-menu label
/// (one of [kE2eCivilianWorkMenuLabels]) becomes hit-testable, using
/// [e2eWaitUntilAnyFinderHitTestable] adaptive backoff (25 → 500 ms cap).
///
/// Lifted from the inline post-`Assign`-tap waits formerly duplicated in
/// [e2eTapFirstAssignInCivilianPanel] (`wait_until_civilian_work_menu`) and
/// [e2eTapAssignOnCivilianRowWithTitle] (`wait_until_civilian_work_menu_row`).
/// Both call sites now delegate here so the label set, the 5 s default
/// timeout, and the underlying poll cadence have a single source of truth.
/// Future callers that tap an `Assign` button (or an upstream affordance that
/// equivalently mounts the work menu) compose this helper directly without
/// duplicating the recipe. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
///
/// Contract:
///
/// - Builds the finder list from [kE2eCivilianWorkMenuLabels] in declaration
///   order so the existential short-circuit inside
///   [e2eWaitUntilAnyFinderHitTestable] resolves in a deterministic order
///   (`Build improvement` first), matching the pre-lift inline blocks.
/// - On timeout, propagates the [TestFailure] raised by
///   [e2eWaitUntilAnyFinderHitTestable] verbatim — the lift does not change
///   fail-fast semantics. The accompanying widget-test pin in
///   `app/test/e2e_await_civilian_work_menu_mounted_test.dart` exercises both
///   the immediate-found fast path and the timeout path so a regression here
///   surfaces in PR checks rather than as a silent late-timeout in the Linux
///   integration suite.
/// - Emits perf timings via the inner [e2eWaitUntilAnyFinderHitTestable] call
///   only — no extra `wait_until_civilian_work_menu_*` counter so repeated
///   waits in a single scenario are still attributable to the existing
///   `wait_until_any_calls` counter.
Future<void> e2eAwaitCivilianWorkMenuMounted(
  WidgetTester tester, {
  Duration timeout = kE2eDefaultCivilianWorkMenuMountTimeout,
  String phaseName = kE2eDefaultCivilianWorkMenuMountPhase,
  E2ePerfLog? perf,
}) async {
  final finders = <Finder>[
    for (final label in kE2eCivilianWorkMenuLabels) find.text(label),
  ];
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    finders,
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
}

/// Taps the first visible **Assign** in the civilian panel work menu (GitHub #2336 H9).
///
/// Settles + taps the resolved Assign via [e2eEnsureVisibleAndTapHitTestable]
/// so the call site picks up the shared `ensureVisible` + `hitTestable()`
/// resolve recipe (the same path the panel-opener rail/marker taps already
/// use). The inline `await tester.pump();` between `ensureVisible` and
/// `tap` is removed because the lifted helper does not insert a settle
/// frame; the shared helper instead resolves `hitTestable()` first and
/// falls back to the raw finder, which is the canonical AC5 / AC10
/// adaptive-pre-tap recipe documented in the e2e-ui-stability rule
/// (Refs GitHub #2336 AC5 / AC10 / Bottleneck 6).
/// Taps the enclosing [CtNinePatchButton] for a button [label] finder, falling
/// back to the shared [e2eEnsureVisibleAndTapHitTestable] label recipe when no
/// `CtNinePatchButton` ancestor resolves (for example a plain `InkWell` work-
/// menu row from `_showOrderMenu`).
///
/// Why this exists (Refs GitHub #2336 AC6 / AC10): `CtNinePatchButton`
/// (`#2859` R1) renders its label inside a `Stack` whose top child is a
/// `Positioned.fill(IgnorePointer(_BrassCornerBrackets))` painted over the
/// engraved-label content, wrapped by a `Material` + `InkWell`. On headless
/// Linux a `tester.tap` aimed at the inner `Text` center resolves to the label
/// glyph rather than the `InkWell`'s gesture region, so the `onPressed`
/// callback (e.g. the civilian-row **Assign** → `_showOrderMenu`) never fires
/// and the downstream work-menu wait times out. Resolving the tap to the
/// enclosing button — the canonical interactive control per
/// `colonizethis-e2e-ui-stability.mdc` (*scope interactions to the actual
/// control*) — fires `onPressed` deterministically.
///
/// Returns `true` when a tap was issued (button ancestor or label fallback),
/// `false` only when [label] resolves to zero elements.
Future<bool> e2eTapEnclosingNinePatchButtonOrLabel(
  WidgetTester tester,
  Finder label,
) async {
  if (label.evaluate().isEmpty) {
    return false;
  }
  final button = find.ancestor(
    of: label,
    matching: find.byType(CtNinePatchButton),
  );
  if (button.evaluate().isEmpty) {
    return e2eEnsureVisibleAndTapHitTestable(tester, label);
  }
  final target = button.first;
  await e2eScrollButtonIntoHitTestableView(tester, target);
  final hit = target.hitTestable();
  final resolved = hit.evaluate().isNotEmpty ? hit.first : target;
  await tester.tap(resolved, warnIfMissed: false);
  return true;
}

/// Best-effort scrolls [button] until it is genuinely **hit-testable**
/// (visible inside the render-view bounds), not merely *built*.
///
/// Why this exists (Refs GitHub #2336 AC6 / AC7 / AC10): a `ListView` keeps
/// rows just outside the viewport laid out (within `cacheExtent`), so they are
/// neither `Offstage` nor removed from the element tree. As a result both
/// `WidgetController.scrollUntilVisible` (which stops as soon as the finder
/// `evaluate()` is non-empty) and a single `tester.ensureVisible` can no-op on
/// a row whose center is still below the render view — e.g. the first civilian
/// **Assign** button laid out at `y≈819` inside a `1280×720` headless view. A
/// `tester.tap` then derives an off-screen offset, misses the hit test, never
/// fires `onPressed`, and the downstream work-menu wait times out. Driving the
/// enclosing `Scrollable` until the button is hit-testable makes the tap land
/// deterministically per `colonizethis-e2e-ui-stability.mdc`
/// (*verify visibility before interaction*).
Future<void> e2eScrollButtonIntoHitTestableView(
  WidgetTester tester,
  Finder button,
) async {
  if (button.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  try {
    await tester.ensureVisible(button);
    await tester.pump();
  } catch (_) {}
  if (button.hitTestable().evaluate().isNotEmpty) {
    return;
  }
  final scrollable = find.ancestor(
    of: button,
    matching: find.byType(Scrollable),
  );
  if (scrollable.evaluate().isEmpty) {
    return;
  }
  const maxScrollSteps = 20;
  for (
    var i = 0;
    i < maxScrollSteps && button.hitTestable().evaluate().isEmpty;
    i++
  ) {
    final dragged = await e2eDragScrollableFromVisiblePoint(
      tester,
      scrollable,
      const Offset(0, -120),
    );
    if (!dragged) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Logical size of the test render view (for example `1280×720` on the headless
/// Linux desktop host). Used to clamp synthetic gesture start points inside the
/// visible bounds.
Size e2eRenderViewSize(WidgetTester tester) {
  return tester.view.physicalSize / tester.view.devicePixelRatio;
}

/// Drags [scrollable] by [delta] starting from a point guaranteed to lie inside
/// both the scrollable's on-screen extent and the render view, returning `true`
/// when a drag was issued.
///
/// Why this exists (Refs GitHub #2336 AC6 / AC7 / AC10): a freshly opened
/// bottom-sheet panel can still be mid entrance-animation, so the `Scrollable`'s
/// geometric center may sit below the render view (observed at `y≈918` in a
/// `1280×720` headless view). A plain `tester.drag(scrollable, ...)` derives its
/// start offset from that off-screen center, misses the hit test, and scrolls
/// nothing — so rows below the fold stay unreachable. Grabbing the on-screen
/// portion of the scrollable instead drives the list deterministically per
/// `colonizethis-e2e-ui-stability.mdc` (*verify visibility before interaction*).
/// Returns `false` when no usable on-screen portion of the scrollable exists.
Future<bool> e2eDragScrollableFromVisiblePoint(
  WidgetTester tester,
  Finder scrollable,
  Offset delta,
) async {
  if (scrollable.evaluate().isEmpty) {
    return false;
  }
  final rect = tester.getRect(scrollable.first);
  final view = e2eRenderViewSize(tester);
  final top = rect.top < 0 ? 0.0 : rect.top;
  final bottom = rect.bottom > view.height ? view.height : rect.bottom;
  if (bottom - top < 8.0) {
    return false;
  }
  final startX = rect.center.dx.clamp(8.0, view.width - 8.0).toDouble();
  final startY = ((top + bottom) / 2).clamp(8.0, view.height - 8.0).toDouble();
  await tester.dragFrom(Offset(startX, startY), delta);
  return true;
}

/// Pumps until [scrollable] has a meaningful on-screen extent (a freshly opened
/// panel has finished sliding up) or [timeout] elapses.
///
/// Guards interactions that target a bottom-sheet panel immediately after it is
/// opened: without this settle the panel's `Scrollable` can still be animating
/// up from the bottom edge, leaving its content below the render view (see
/// [e2eDragScrollableFromVisiblePoint]). Refs GitHub #2336 AC6 / AC7 / AC10.
Future<void> e2eWaitScrollableOnScreen(
  WidgetTester tester,
  Finder scrollable, {
  Duration timeout = const Duration(seconds: 5),
  String phaseName = 'pump_until_panel_scrollable_onscreen',
}) async {
  await e2ePumpUntilConditionOrIdle(
    tester,
    () {
      if (scrollable.evaluate().isEmpty) {
        return false;
      }
      final rect = tester.getRect(scrollable.first);
      final view = e2eRenderViewSize(tester);
      final top = rect.top < 0 ? 0.0 : rect.top;
      final bottom = rect.bottom > view.height ? view.height : rect.bottom;
      return bottom - top > 40.0;
    },
    timeout: timeout,
    phaseName: phaseName,
  );
}
