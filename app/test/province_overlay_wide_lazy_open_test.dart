// Wide-layout deferred MAP20001 sections (Refs #4690 Slice C).

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_sea_zone_overlay_detail_paths_support.dart';

Set<String> _sectionLabelTexts(WidgetTester tester) {
  return tester
      .widgetList<CtSectionLabel>(find.byType(CtSectionLabel))
      .map((w) => w.text)
      .toSet();
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'wide MAP20001 defers Economic section body until scroll (Refs #4690)',
    (WidgetTester tester) async {
      final binding = tester.view;
      final oldSize = binding.physicalSize;
      final oldRatio = binding.devicePixelRatio;
      addTearDown(() {
        binding.physicalSize = oldSize;
        binding.devicePixelRatio = oldRatio;
      });
      binding.physicalSize = const Size(1280, 280);
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

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(
        _sectionLabelTexts(tester),
        contains(l10n.provinceOverlay_sectionEconomic),
      );
      expect(find.text(l10n.provinceOverlay_extractionHeading), findsNothing);

      await tester.scrollUntilVisible(
        find.byWidgetPredicate(
          (widget) =>
              widget is CtSectionLabel &&
              widget.text == l10n.provinceOverlay_sectionEconomic,
        ),
        120,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(l10n.provinceOverlay_extractionHeading), findsWidgets);
    },
  );
}
