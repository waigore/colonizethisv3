// Lazy narrow-tab open path for MAP20001 (Refs #4690 Slice A).

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_sea_zone_overlay_detail_paths_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'narrow MAP20001 defers Economic tab body until first selection (Refs #4690)',
    (WidgetTester tester) async {
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
      await tester.pump();

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.provinceOverlay_sectionEconomic), findsOneWidget);
      expect(find.text(l10n.provinceOverlay_extractionHeading), findsNothing);

      await tester.tap(find.text(l10n.provinceOverlay_sectionEconomic));
      await tester.pump();

      expect(find.text(l10n.provinceOverlay_extractionHeading), findsWidgets);
    },
  );
}
