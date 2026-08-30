import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_extraction_available_test_support.dart';
import 'province_overlay_owned_pump.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'Extraction and Available appear above Town production (Refs #4002)',
    (tester) async {
      await pumpOwnedProvinceOverlayAtDarkTheme(
        tester,
        omniscientDetail: true,
        extractionSnapshot: sampleProvinceExtractionSnapshot(
          demoOverlayHumanId(),
        ),
        availableByCommodity: sampleProvinceImprovableAvailable,
      );

      expect(find.text('Extraction'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Town production'), findsOneWidget);
      expect(find.textContaining('1 (5)'), findsOneWidget);
      expect(find.textContaining('5 Iron'), findsOneWidget);
      expect(find.textContaining('3 Grain'), findsOneWidget);
      expect(find.textContaining('2 Timber'), findsOneWidget);

      final extractionY = tester.getTopLeft(find.text('Extraction')).dy;
      final availableY = tester.getTopLeft(find.text('Available')).dy;
      final townY = tester.getTopLeft(find.text('Town production')).dy;
      expect(extractionY, lessThan(availableY));
      expect(availableY, lessThan(townY));
    },
  );

  testWidgets(
    'partial Extraction shows muted reason line under condensed line (Refs #4150)',
    (tester) async {
      await pumpOwnedProvinceOverlayAtDarkTheme(
        tester,
        omniscientDetail: true,
        extractionSnapshot: sampleProvinceExtractionSnapshot(
          demoOverlayHumanId(),
        ),
        availableByCommodity: sampleProvinceImprovableAvailable,
      );

      expect(
        find.text(
          'Some improved tiles are not linked to your capital, or the road/port path is too weak.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('full-yield Extraction omits partial reason line (Refs #4150)', (
    tester,
  ) async {
    final humanId = demoOverlayHumanId();
    await pumpOwnedProvinceOverlayAtDarkTheme(
      tester,
      omniscientDetail: true,
      extractionSnapshot: ProvinceExtractionSnapshot(
        ownerId: humanId,
        byCommodity: {
          'grain': const ProvinceExtractionCommodityTotals(
            effective: 5,
            full: 5,
            tileKeys: ['oldWorld|p1|0|0'],
          ),
        },
      ),
    );

    expect(
      find.text(
        'Some improved tiles are not linked to your capital, or the road/port path is too weak.',
      ),
      findsNothing,
    );
  });

  testWidgets('empty Extraction shows dash placeholders (Refs #4002)', (
    tester,
  ) async {
    await pumpOwnedProvinceOverlayAtDarkTheme(tester, omniscientDetail: true);

    expect(find.text('Extraction'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets(
    'intel gate hides Extraction/Available quantities behind ??? (Refs #4002)',
    (tester) async {
      final humanId = demoOverlayHumanId();
      await pumpOwnedProvinceOverlayAtDarkTheme(
        tester,
        displayId: foreignOwnedProvinceIdForOverlay(
          game: demoGameForOwnedPump(),
          humanPlayerId: humanId,
        ),
        omniscientDetail: false,
        extractionSnapshot: sampleProvinceExtractionSnapshot(humanId),
        availableByCommodity: sampleProvinceImprovableAvailable,
      );

      expect(find.text('Extraction'), findsNothing);
      expect(find.text('Available'), findsNothing);
      expect(find.textContaining('1 (5)'), findsNothing);
      expect(find.textContaining('3 Grain'), findsNothing);
      expect(find.text('???'), findsWidgets);
    },
  );

  testWidgets(
    'hovering Extraction commodity highlights related tile keys (Refs #4002)',
    (tester) async {
      Iterable<String>? highlighted;

      await pumpOwnedProvinceOverlayAtDarkTheme(
        tester,
        omniscientDetail: true,
        extractionSnapshot: sampleProvinceExtractionSnapshot(
          demoOverlayHumanId(),
        ),
        availableByCommodity: sampleProvinceImprovableAvailable,
        onHighlightTiles: (keys) {
          highlighted = keys;
        },
      );

      final grainSegment = find.textContaining('1 (5)');
      expect(grainSegment, findsOneWidget);
      final mouseRegions = find.ancestor(
        of: grainSegment,
        matching: find.byType(MouseRegion),
      );
      expect(mouseRegions, findsWidgets);
      final region = tester.widget<MouseRegion>(mouseRegions.first);
      region.onEnter!(const PointerEnterEvent());
      expect(highlighted, ['oldWorld|p1|0|0', 'oldWorld|p1|0|1']);
      region.onExit!(const PointerExitEvent());
      expect(highlighted, isNull);
    },
  );

  testWidgets(
    'narrow shell wraps Extraction segments without ellipsis (Refs #4002)',
    (tester) async {
      await pumpOwnedProvinceOverlayAtDarkTheme(
        tester,
        omniscientDetail: true,
        shellWidth: 160,
        extractionSnapshot: ProvinceExtractionSnapshot(
          ownerId: demoOverlayHumanId(),
          byCommodity: {
            for (final id in const [
              'grain',
              'meat',
              'wool',
              'timber',
              'iron',
              'copper',
            ])
              id: ProvinceExtractionCommodityTotals(
                effective: 2,
                full: 2,
                tileKeys: ['oldWorld|p1|0|0'],
              ),
          },
        ),
      );

      expect(find.textContaining('2 Grain'), findsOneWidget);
      expect(find.textContaining('2 Meat'), findsOneWidget);
      expect(find.textContaining('2 Wool'), findsOneWidget);
      expect(find.textContaining('2 Timber'), findsOneWidget);
      expect(find.textContaining('2 Iron'), findsOneWidget);
      expect(find.textContaining('2 Copper'), findsOneWidget);
      expect(find.byType(Wrap), findsWidgets);
      final ellipsized = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.overflow == TextOverflow.ellipsis);
      expect(ellipsized, isEmpty);
    },
  );

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

  testWidgets('capital grain bonus annotation is not a hover-highlight target '
      '(Refs #4064)', (tester) async {
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
  });
}
