// Visual goldens for MAP20001 Military Train variants (Refs #4769).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

class _TrainMilitaryGoldenCase {
  const _TrainMilitaryGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.show,
    required this.size,
    this.overlayWidth,
  });

  final String name;
  final String goldenFile;
  final bool show;
  final Size size;
  final double? overlayWidth;
}

const _cases = [
  _TrainMilitaryGoldenCase(
    name: 'Military Train enabled',
    goldenFile: 'goldens/province_overlay_train_military_enabled.png',
    show: true,
    size: Size(640, 720),
  ),
  _TrainMilitaryGoldenCase(
    name: 'Military Train hidden',
    goldenFile: 'goldens/province_overlay_train_military_hidden.png',
    show: false,
    size: Size(640, 720),
  ),
  _TrainMilitaryGoldenCase(
    name: 'Military Train 320 dp wrap',
    goldenFile: 'goldens/province_overlay_train_military_320dp.png',
    show: true,
    size: Size(640, 720),
    overlayWidth: 320,
  ),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4769)', (tester) async {
      await configureGoldenSurface(tester, size: c.size);
      configureGoldenView(tester, physicalSize: c.size, devicePixelRatio: 1.0);
      final boundaryKey = ValueKey<String>('province_overlay_${c.name}_golden');
      final game = demoGameForOverlay;
      final overlayWidth = c.overlayWidth ?? 460.0;
      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          child: SizedBox(
            width: overlayWidth,
            height: c.size.height - 40,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              showTrainMilitaryControl: c.show,
              onTrainMilitaryTap: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);
      expect(tester.takeException(), isNull);
      final militaryHeader = find.text(
        l10n.provinceOverlay_sectionMilitary.toUpperCase(),
      );
      expect(militaryHeader, findsOneWidget);
      await tester.ensureVisible(militaryHeader);
      await tester.pump();
      final finder = find.byKey(kProvinceOverlayTrainMilitaryKey);
      if (c.show) {
        expect(finder, findsOneWidget);
        expect(tester.widget<CtActionTextButton>(finder).enabled, isTrue);
        expect(
          find.text(l10n.provinceOverlay_trainMilitaryGist),
          findsOneWidget,
        );
        await tester.ensureVisible(finder);
        await tester.pump();
      } else {
        expect(finder, findsNothing);
      }
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }
}
