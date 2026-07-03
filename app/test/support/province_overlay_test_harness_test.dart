// Smoke tests for the shared province-overlay dark-theme pump harness (Refs #3847).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show demoGameForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

import 'province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets('buildProvinceOverlayDarkThemeShell drives editorialMonocle', (
    WidgetTester tester,
  ) async {
    final game = demoGameForOverlay;
    final displayId = ownedProvinceIdInOldWorld(
      game: game,
      ownerId: game.players.first.id,
    );

    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: game,
      displayId: displayId,
    );

    expect(tester.takeException(), isNull);
    expect(
      Theme.of(
        tester.element(find.byType(ProvinceSeaZoneDetailOverlay)),
      ).colorScheme,
      AppThemes.editorialMonocle.colorScheme,
    );
  });

  testWidgets('buildProvinceOverlayWithRevealedDemoTile mounts sample tile', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildProvinceOverlayWithRevealedDemoTile());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
  });
}
