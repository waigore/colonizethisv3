// Capital grain bonus and hover pins for extraction/available overlay rows.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_extraction_available_test_support.dart';
import 'province_overlay_owned_pump.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'capital grain bonus annotation is muted and distinct (Refs #4064)',
    (tester) async {
      await pumpOwnedProvinceOverlayAtDarkTheme(
        tester,
        omniscientDetail: true,
        extractionSnapshot: sampleProvinceExtractionSnapshot(
          demoOverlayHumanId(),
          capitalGrainBonus: 2,
        ),
        availableByCommodity: sampleProvinceImprovableAvailable,
      );

      expect(
        find.textContaining('incl. +2 capital grain bonus'),
        findsOneWidget,
      );
      final annotation = tester.widget<Text>(
        find.textContaining('incl. +2 capital grain bonus'),
      );
      expect(annotation.style?.color, EditorialMonoclePalette.muted);
    },
  );

  testWidgets(
    'capital grain bonus annotation is not a hover-highlight target (Refs #4064)',
    (tester) async {
      Iterable<String>? highlighted;

      await pumpOwnedProvinceOverlayAtDarkTheme(
        tester,
        omniscientDetail: true,
        extractionSnapshot: sampleProvinceExtractionSnapshot(
          demoOverlayHumanId(),
          capitalGrainBonus: 2,
        ),
        availableByCommodity: sampleProvinceImprovableAvailable,
        onHighlightTiles: (keys) {
          highlighted = keys;
        },
      );

      final bonus = find.textContaining('incl. +2 capital grain bonus');
      expect(bonus, findsOneWidget);
      expect(
        find.ancestor(of: bonus, matching: find.byType(MouseRegion)),
        findsNothing,
      );

      final grainSegment = find.textContaining('1 (5)');
      expect(grainSegment, findsOneWidget);
      final grainRegions = find.ancestor(
        of: grainSegment,
        matching: find.byType(MouseRegion),
      );
      expect(grainRegions, findsWidgets);
      tester.widget<MouseRegion>(grainRegions.first).onEnter!(
        const PointerEnterEvent(),
      );
      expect(highlighted, ['oldWorld|p1|0|0', 'oldWorld|p1|0|1']);
    },
  );
}
