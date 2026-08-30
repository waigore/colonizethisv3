// Wide vs narrow MAP20001 overlay section layout (Refs #2865, #4642).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_sea_zone_overlay_detail_paths_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('AC: Narrow layout uses tab strip for overlay sections', (
    WidgetTester tester,
  ) async {
    final binding = tester.view;
    final oldSize = binding.physicalSize;
    final oldRatio = binding.devicePixelRatio;
    addTearDown(() {
      binding.physicalSize = oldSize;
      binding.devicePixelRatio = oldRatio;
    });
    binding.physicalSize = const Size(400, 2000);
    binding.devicePixelRatio = 1.0;

    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    final selection = firstRevealedLandOverlaySelection(
      game: game,
      region: region,
    );
    expect(selection.selectedTileKey, isNotNull);

    await tester.pumpWidget(
      buildProvinceSeaZoneOverlayPathShell(
        game: game,
        region: region,
        displayId: selection.provinceId,
        humanPlayerId: game.players.first.id,
        selectedTileKey: selection.selectedTileKey,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CtTabStrip), findsOneWidget);
  });

  testWidgets('AC: Wide layout renders a single scrollable column of all six '
      'sections without a tab strip', (WidgetTester tester) async {
    final binding = tester.view;
    final oldSize = binding.physicalSize;
    final oldRatio = binding.devicePixelRatio;
    addTearDown(() {
      binding.physicalSize = oldSize;
      binding.devicePixelRatio = oldRatio;
    });
    binding.physicalSize = const Size(1200, 2000);
    binding.devicePixelRatio = 1.0;

    final game = demoGameForOverlay;
    final region = demoRegionForOverlay;
    final selection = firstRevealedLandOverlaySelection(
      game: game,
      region: region,
    );
    expect(selection.selectedTileKey, isNotNull);

    await tester.pumpWidget(
      buildProvinceSeaZoneOverlayPathShell(
        game: game,
        region: region,
        displayId: selection.provinceId,
        humanPlayerId: game.players.first.id,
        selectedTileKey: selection.selectedTileKey,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CtTabStrip), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ProvinceSeaZoneDetailOverlay),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    expect(find.byType(CtSectionLabel), findsNWidgets(6));
    for (final header in const <String>[
      'POLITICAL',
      'TILE',
      'ECONOMIC',
      'MILITARY',
      'CIVILIAN',
      'NAVAL',
    ]) {
      expect(
        find.text(header),
        findsOneWidget,
        reason:
            'Wide layout must render the $header section header in the '
            'single scrollable column.',
      );
    }
  });
}
