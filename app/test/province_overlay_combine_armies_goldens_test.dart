// Visual goldens for MAP20001 Military Combine variants (Refs #4610).

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

class _CombineGoldenCase {
  const _CombineGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.show,
    required this.enabled,
    this.tooltip = '',
  });

  final String name;
  final String goldenFile;
  final bool show;
  final bool enabled;
  final String tooltip;
}

const _cases = [
  _CombineGoldenCase(
    name: 'Military Combine enabled',
    goldenFile: 'goldens/province_overlay_combine_enabled.png',
    show: true,
    enabled: true,
  ),
  _CombineGoldenCase(
    name: 'Military Combine Home Army target',
    goldenFile: 'goldens/province_overlay_combine_home_army.png',
    show: true,
    enabled: true,
  ),
  _CombineGoldenCase(
    name: 'Military Combine pending-move disabled',
    goldenFile: 'goldens/province_overlay_combine_pending_disabled.png',
    show: true,
    enabled: false,
    tooltip: 'Cancel the pending march before combining these armies.',
  ),
  _CombineGoldenCase(
    name: 'Military Combine hidden',
    goldenFile: 'goldens/province_overlay_combine_hidden.png',
    show: false,
    enabled: false,
  ),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4610)', (tester) async {
      await configureGoldenSurface(tester, size: const Size(640, 720));
      configureGoldenView(
        tester,
        physicalSize: const Size(640, 720),
        devicePixelRatio: 1.0,
      );
      final boundaryKey = ValueKey<String>('province_overlay_${c.name}_golden');
      final game = demoGameForOverlay;
      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          child: SizedBox(
            width: 460,
            height: 680,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: game.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              showCombineArmiesControl: c.show,
              combineArmiesEnabled: c.enabled,
              combineArmiesTooltip: c.tooltip,
              onCombineArmiesTap: () {},
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);
      expect(tester.takeException(), isNull);
      final finder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_combineArmiesAction,
      );
      if (c.show) {
        expect(finder, findsOneWidget);
        expect(tester.widget<CtActionTextButton>(finder).enabled, c.enabled);
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
