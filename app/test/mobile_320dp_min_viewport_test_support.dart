// Shared 320 dp main-menu / leader-dialog pumps (Refs #4352).
// SPEC: SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app_fixtures/runtime/app_display_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md
/// § 7. Width matches [kMinViewportWidth]; height (640 dp) is the lower end
/// of the iPhone SE-class mobile envelope mockups target.
const Size kMobileMinViewport = Size(kMinViewportWidth, 640);

/// Viewport used by the negative-regression pin: comfortably wider than
/// every per-screen breakpoint so the same screens render their wide layout
/// without any responsive concessions.
const Size kMobileWideRegressionViewport = Size(1024, 768);

Widget wrapMainMenuForMinViewport({
  MainMenuVariant variant = MainMenuVariant.plain,
  MainMenuState state = MainMenuState.default_,
}) {
  return CtMainMenu(
    variant: variant,
    state: state,
    version: formatDebugAwareVersion('v1.0.0'),
    onNewGame: () {},
    onLoadGame: () {},
    onSettings: () {},
    onQuit: () {},
  );
}

/// Pumps [screen] at [size] and asserts the framework emitted no exception.
///
/// When [settleAnimations] is `true` (default) the helper drives
/// `pumpAndSettle()` to completion. When `false` it pumps a small finite
/// number of frames instead so screens with **continuous** animations can
/// still be exercised against the layout overflow contract.
Future<void> pumpMobileNarrow(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  bool settleAnimations = true,
}) async {
  if (settleAnimations) {
    await pumpAtMinViewport(tester, size: size, child: screen, settle: true);
    return;
  }
  await pumpAtMinViewport(tester, size: size, child: screen);
  await tester.pump();
}

List<double> renderedNinePatchButtonHeights(WidgetTester tester) {
  final Iterable<Element> elements = find.byType(CtNinePatchButton).evaluate();
  final List<double> heights = <double>[];
  for (final Element element in elements) {
    final RenderBox? box = element.renderObject as RenderBox?;
    if (box == null || !box.hasSize) continue;
    heights.add(box.size.height);
  }
  return heights;
}

void expectMobileTouchTargets(
  WidgetTester tester, {
  required bool requireButtons,
}) {
  expect(tester.takeException(), isNull);
  final heights = renderedNinePatchButtonHeights(tester);
  if (requireButtons) {
    expect(
      heights,
      isNotEmpty,
      reason:
          'CtMainMenu must render at least one CtNinePatchButton '
          '(New Game / Load Game / Settings / Quit).',
    );
  }
  for (final h in heights) {
    expect(
      h,
      greaterThanOrEqualTo(kMinTouchTargetSize),
      reason:
          'CtNinePatchButton height $h dp violates the 44 dp '
          'touch-target minimum at the 320 dp viewport.',
    );
  }
}
