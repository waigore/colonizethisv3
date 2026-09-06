// Pump helpers for game_screen_narrow_shell_chrome_test (Refs #4734 Slice H).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_test_support.dart';

void bindGameScreenNarrowShellSurface(
  WidgetTester tester, {
  double width = 1500,
  double height = 700,
}) {
  final dpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  addTearDown(tester.view.reset);
}

Future<void> pumpGameScreenNarrowShellChrome(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required Game baseGame,
  required InitGameMapViewData lightMapViewData,
  double width = 1500,
  double height = 700,
  bool bindWide = false,
  TreasurySummary treasurySummary = const TreasurySummary(treasury: 12345),
}) async {
  if (bindWide) {
    bindGameScreenNarrowShellSurface(tester, width: width, height: height);
  }
  await tester.pumpWidget(
    buildGameScreenHost(
      gamesBox: gamesBox,
      game: baseGame,
      mapViewData: lightMapViewData,
      width: width,
      height: height,
      navigatorKey: appNavigatorKey,
      treasurySummary: treasurySummary,
    ),
  );
  await tester.pump();
}

String? strictAssetIconPathUnder(WidgetTester tester, Finder ancestor) {
  final iconFinder = find.descendant(
    of: ancestor,
    matching: find.byType(StrictAssetIcon),
  );
  expect(iconFinder, findsOneWidget);
  return tester.widget<StrictAssetIcon>(iconFinder).assetPath;
}
