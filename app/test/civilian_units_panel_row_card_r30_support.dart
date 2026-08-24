// Shared row-card chrome fixtures for CivilianUnitsPanel R30 tests (Refs #2866 / #4642).

import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'civilian_units_panel_test_support.dart';

int civilianRowCardArgb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

const kCivilianRowCardHumanId = 'h1';
const kCivilianRowCardTileKey = 'oldWorld|p1|0|0';
const kCivilianRowCardProvinceId = 'oldWorld|p1';

Game civilianRowCardMiniGame({int civilianCount = 1}) {
  return buildCivilianOwUnitsGame(
    id: 'g_civ_row_card_r30',
    humanId: kCivilianRowCardHumanId,
    units: [
      for (int i = 0; i < civilianCount; i++)
        civilianIdleUnit(
          id: 'civ_$i',
          type: i == 0 ? kUnitTypeBuilder : kUnitTypeEngineer,
          ownerId: kCivilianRowCardHumanId,
          provinceId: kCivilianRowCardProvinceId,
          tileKey: kCivilianRowCardTileKey,
        ),
    ],
  );
}

Widget wrapCivilianRowCardHost(Widget child) {
  return buildAppShell(
    overrides: [
      availableWorkTargetIdsForUnitProvider.overrideWith(
        (ref, _) => const <String>[],
      ),
    ],
    child: Scaffold(body: child),
  );
}

DecoratedBox civilianRowCardDecoratedBox(WidgetTester tester, Finder card) {
  final decoratedFinder = find.descendant(
    of: card,
    matching: find.byType(DecoratedBox),
  );
  expect(decoratedFinder, findsAtLeastNWidgets(1));
  return tester.widget<DecoratedBox>(decoratedFinder.first);
}
