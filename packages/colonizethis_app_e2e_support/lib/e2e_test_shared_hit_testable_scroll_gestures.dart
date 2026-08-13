import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_adaptive_polling.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_hit_testable_tap.dart';

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
