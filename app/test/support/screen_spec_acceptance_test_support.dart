// Shared CtMainMenu frames and finders for screen_spec_acceptance_part*_test
// (Refs #4013). Pins SPEC/ui/main-menu.md under colonial / editorial themes.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app_fixtures/runtime/app_display_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Colonial-theme Material frame hosting [CtMainMenu] for SPEC AC pins.
Widget buildScreenSpecMainMenu({
  MainMenuState state = MainMenuState.default_,
  MainMenuVariant variant = MainMenuVariant.plain,
  bool resumeGameVisible = false,
  VoidCallback? onResumeGame,
  required VoidCallback onNewGame,
  required VoidCallback onLoadGame,
  required VoidCallback onSettings,
  required VoidCallback onQuit,
}) {
  return MaterialApp(
    theme: AppThemes.colonial,
    home: CtMainMenu(
      variant: variant,
      state: state,
      version: formatDebugAwareVersion('v1.0.0'),
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
        onNewGame: () {},
        onLoadGame: () {},
        onSettings: () {},
        onQuit: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}
