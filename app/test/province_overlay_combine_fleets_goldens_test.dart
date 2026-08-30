// Visual goldens for MAP20001 Naval Combine variants (Refs #4659).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_combine_overlay_controls.dart';
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
    name: 'Naval Combine enabled',
    goldenFile: 'goldens/province_overlay_combine_fleets_enabled.png',
    show: true,
    enabled: true,
  ),
  _CombineGoldenCase(
    name: 'Naval Combine Home Fleet target',
    goldenFile: 'goldens/province_overlay_combine_fleets_home.png',
    show: true,
    enabled: true,
  ),
  _CombineGoldenCase(
    name: 'Naval Combine sea-zone enabled',
    goldenFile: 'goldens/province_overlay_combine_fleets_sea.png',
    show: true,
    enabled: true,
  ),
  _CombineGoldenCase(
    name: 'Naval Combine pending-order disabled',
    goldenFile: 'goldens/province_overlay_combine_fleets_pending.png',
    show: true,
    enabled: false,
    tooltip: 'Cancel the pending sail or mission before combining these fleets.',
  ),
  _CombineGoldenCase(
    name: 'Naval Combine Home non-transfer source',
    goldenFile: 'goldens/province_overlay_combine_fleets_home_nontransfer.png',
    show: true,
    enabled: true,
  ),
  _CombineGoldenCase(
    name: 'Naval Combine hidden',
    goldenFile: 'goldens/province_overlay_combine_fleets_hidden.png',
    show: false,
    enabled: false,
  ),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4659)', (tester) async {
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
              navalCombine: ProvinceNavalCombineOverlayControls(
                showCombineFleets: c.show,
                combineFleetsEnabled: c.enabled,
                combineFleetsTooltip: c.tooltip.isEmpty
                    ? (c.enabled
                          ? l10n.provinceOverlay_combineFleetsAction
                          : l10n.provinceOverlay_combineFleetsPendingOrderTooltip)
                    : c.tooltip,
                onCombineFleetsTap: () {},
              ),
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);
      expect(tester.takeException(), isNull);
      final finder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_combineFleetsAction,
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
