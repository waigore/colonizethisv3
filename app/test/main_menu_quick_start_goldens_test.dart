// Widget goldens for SHEL10002 Quick Start (Refs #4416).
// Pixel baselines under `app/test/goldens/` close the verify-github-issue
// UI proof gap flagged on issue #4416 after PR #4419 merged.
//
// Golden mapping:
//  - AC 1  pixelArt menu: Quick Start above New Game + muted helper
//  - AC 6  320×640 with Resume visible: ≥44 dp targets, scroll if needed
//
// SPEC: SPEC/ui/main-menu.md § Visibility / Resume / Automated tests;
// SPEC/ui/mobile-adaptation.md § 7.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:colonizethis_app/widgets/main_menu_constants.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'mobile_320dp_min_viewport_test_support.dart';
import 'widget_test_assets.dart';

const Size _desktopMenuViewport = Size(800, 720);
const String _quickStartHelper =
    'Play as England, turn 0, random map, five AI courts.';

Widget _pixelArtMenu({required bool resumeGameVisible}) {
  return CtMainMenu(
    variant: MainMenuVariant.pixelArt,
    state: MainMenuState.default_,
    version: 'v1.0.0',
    onQuickStart: () {},
    onNewGame: () {},
    resumeGameVisible: resumeGameVisible,
    onResumeGame: resumeGameVisible ? () {} : null,
    onLoadGame: () {},
    onSettings: () {},
    onQuit: () {},
  );
}

Future<void> _pumpMenuGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Size viewport,
  required bool resumeGameVisible,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    center: false,
    useScaffold: false,
    includeLocalizations: true,
    settle: false,
    child: SizedBox(
      width: viewport.width,
      height: viewport.height,
      child: _pixelArtMenu(resumeGameVisible: resumeGameVisible),
    ),
  );
}

void _expectQuickStartAboveNewGame(WidgetTester tester) {
  expect(find.text('Quick Start'), findsOneWidget);
  expect(find.text(_quickStartHelper), findsOneWidget);
  expect(find.text('New Game'), findsOneWidget);
  final double quickDy = tester.getTopLeft(find.text('Quick Start')).dy;
  final double helperDy = tester.getTopLeft(find.text(_quickStartHelper)).dy;
  final double newGameDy = tester.getTopLeft(find.text('New Game')).dy;
  expect(quickDy, lessThan(helperDy));
  expect(helperDy, lessThan(newGameDy));
  final Finder quickButton = find.ancestor(
    of: find.text('Quick Start'),
    matching: find.byType(CtNinePatchButton),
  );
  expect(tester.widget<CtNinePatchButton>(quickButton).onPressed, isNotNull);
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  testWidgets(
    'AC1 golden: pixelArt Quick Start sits above New Game with helper',
    (WidgetTester tester) async {
      const Key boundaryKey = ValueKey<String>('mainMenuQuickStartPixelGolden');
      await _pumpMenuGolden(
        tester,
        boundaryKey: boundaryKey,
        viewport: _desktopMenuViewport,
        resumeGameVisible: false,
      );
      expect(tester.takeException(), isNull);
      _expectQuickStartAboveNewGame(tester);
      expect(find.text('Resume game'), findsNothing);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/main_menu_quick_start_pixel.png'),
      );
    },
  );

  testWidgets('AC6 golden: 320×640 Resume-visible menu keeps ≥44 dp targets', (
    WidgetTester tester,
  ) async {
    const Key boundaryKey = ValueKey<String>(
      'mainMenuQuickStart320ResumeGolden',
    );
    await _pumpMenuGolden(
      tester,
      boundaryKey: boundaryKey,
      viewport: kMobileMinViewport,
      resumeGameVisible: true,
    );
    expect(tester.takeException(), isNull);
    _expectQuickStartAboveNewGame(tester);
    expect(find.text('Resume game'), findsOneWidget);
    expect(find.text('Load Game'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expectMobileTouchTargets(tester, requireButtons: true);
    final Size quitSize = tester.getSize(
      find.byKey(const Key(kMainMenuFooterQuitKey)),
    );
    expect(quitSize.height, greaterThanOrEqualTo(kMinTouchTargetSize));
    expect(quitSize.width, greaterThanOrEqualTo(kMinTouchTargetSize));
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/main_menu_quick_start_320dp_resume.png'),
    );
  });
}
