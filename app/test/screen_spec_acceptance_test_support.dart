// Shared CtMainMenu frames and finders for screen_spec_acceptance_*_test
// (Refs #4013). Pins SPEC/ui/main-menu.md under colonial / editorial themes.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app_fixtures/runtime/app_display_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

/// Colonial-theme Material frame hosting [CtMainMenu] for SPEC AC pins.
Widget buildScreenSpecMainMenu({
  MainMenuState state = MainMenuState.default_,
  MainMenuVariant variant = MainMenuVariant.plain,
  bool resumeGameVisible = false,
  VoidCallback? onResumeGame,
  VoidCallback? onQuickStart,
  required VoidCallback onNewGame,
  required VoidCallback onLoadGame,
  required VoidCallback onSettings,
  required VoidCallback onQuit,
}) {
  // Colonial specialization via buildAppShell theme (Refs #4035).
  return buildAppShell(
    theme: AppThemes.colonial,
    child: CtMainMenu(
      variant: variant,
      state: state,
      version: formatDebugAwareVersion('v1.0.0'),
      onQuickStart: onQuickStart ?? () {},
      onNewGame: onNewGame,
      resumeGameVisible: resumeGameVisible,
      onResumeGame: onResumeGame,
      onLoadGame: onLoadGame,
      onSettings: onSettings,
      onQuit: onQuit,
    ),
  );
}

/// Locates the `CtNinePatchButton` ancestor of the menu label [label] so
/// tests can drive press gestures against the wood-panel surface itself.
Finder woodPanelButtonFinderFor(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(CtNinePatchButton),
  );
}

/// Returns the gradient-painting `DecoratedBox` painted by the
/// `CtNinePatchButton` whose label is [label]. The button paints exactly
/// one such box (the surface), so the finder is unambiguous.
DecoratedBox findGradientSurfaceFor(WidgetTester tester, String label) {
  final Finder boxes = find.descendant(
    of: woodPanelButtonFinderFor(label),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient != null,
    ),
  );
  expect(
    boxes,
    findsAtLeastNWidgets(1),
    reason:
        'CtNinePatchButton for "$label" must paint a gradient surface '
        'DecoratedBox',
  );
  return tester.widget<DecoratedBox>(boxes.first);
}

/// Default-size [CtMainMenu] pump for pixelArt chrome ACs (Refs #4352).
Future<void> pumpScreenSpecMainMenu(
  WidgetTester tester, {
  MainMenuVariant variant = MainMenuVariant.plain,
  VoidCallback? onQuit,
  bool resumeGameVisible = false,
  VoidCallback? onResumeGame,
}) async {
  await tester.pumpWidget(
    buildScreenSpecMainMenu(
      variant: variant,
      resumeGameVisible: resumeGameVisible,
      onResumeGame: onResumeGame,
      onQuickStart: () {},
      onNewGame: () {},
      onLoadGame: () {},
      onSettings: () {},
      onQuit: onQuit ?? () {},
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps the plain-variant main menu used by the AC 8 negative gradient pin.
Future<void> pumpScreenSpecPlainMainMenu(WidgetTester tester) async {
  await tester.pumpWidget(
    buildAppShell(
      child: CtMainMenu(
        variant: MainMenuVariant.plain,
        state: MainMenuState.default_,
        version: formatDebugAwareVersion('v1.0.0'),
        onQuickStart: () {},
        onNewGame: () {},
        onLoadGame: () {},
        onSettings: () {},
        onQuit: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// AC 8: wood-panel button held/released gradient cycle for [label].
Future<void> expectScreenSpecWoodPanelGradientPressCycle(
  WidgetTester tester,
  String label,
) async {
  final Finder button = woodPanelButtonFinderFor(label);
  final Offset center = tester.getCenter(button);
  final TestGesture gesture = await tester.startGesture(center);
  await tester.pump();
  await tester.pumpAndSettle();

  final LinearGradient pressedGradient =
      (findGradientSurfaceFor(tester, label).decoration as BoxDecoration)
          .gradient! as LinearGradient;
  expect(
    pressedGradient.colors,
    CtGradients.woodPanelButtonGradientPressed.colors,
  );

  await gesture.up();
  await tester.pumpAndSettle();

  final LinearGradient releasedGradient =
      (findGradientSurfaceFor(tester, label).decoration as BoxDecoration)
          .gradient! as LinearGradient;
  expect(releasedGradient.colors, CtGradients.woodPanelButtonGradient.colors);
}

/// Texts whose style letter-spacing matches [spacing].
Finder textsWithLetterSpacing(double spacing) => find.byWidgetPredicate(
  (Widget w) => w is Text && w.style?.letterSpacing == spacing,
);

/// Pumps [CtMainMenu] at an explicit viewport size for responsive ACs.
Future<void> pumpScreenSpecMainMenuAtSize(
  WidgetTester tester, {
  required Size size,
  required MainMenuVariant variant,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: size),
      child: buildScreenSpecMainMenu(
        variant: variant,
        onQuickStart: () {},
        onNewGame: () {},
        onLoadGame: () {},
        onSettings: () {},
        onQuit: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}
