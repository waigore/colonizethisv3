// Visual goldens for MAP20001 Civilian Station spy variants (Refs #4439).
// SPEC/ui/province-sea-zone-detail-overlay.md § States and variants.

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

class _StationSpyGoldenCase {
  const _StationSpyGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showControl,
    required this.enabled,
    this.tooltip = '',
  });

  final String name;
  final String goldenFile;
  final bool showControl;
  final bool enabled;
  final String tooltip;
}

const List<_StationSpyGoldenCase> _cases = [
  _StationSpyGoldenCase(
    name: 'Civilian Station spy enabled',
    goldenFile: 'goldens/province_overlay_station_spy_enabled.png',
    showControl: true,
    enabled: true,
  ),
  _StationSpyGoldenCase(
    name: 'Civilian Station spy disabled',
    goldenFile: 'goldens/province_overlay_station_spy_disabled.png',
    showControl: true,
    enabled: false,
    tooltip: 'No idle Spy can relocate here.',
  ),
  _StationSpyGoldenCase(
    name: 'Civilian Station spy hidden',
    goldenFile: 'goldens/province_overlay_station_spy_hidden.png',
    showControl: false,
    enabled: false,
  ),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4439)', (WidgetTester tester) async {
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
              stationSpy: (
                showControl: c.showControl,
                enabled: c.enabled,
                tooltip: c.tooltip,
                onTap: () {},
              ),
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);
      expect(tester.takeException(), isNull);

      final civilianHeader = find.text(
        l10n.provinceOverlay_sectionCivilian.toUpperCase(),
      );
      expect(civilianHeader, findsOneWidget);
      await tester.ensureVisible(civilianHeader);
      await tester.pump();

      final spyFinder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_stationSpyAction,
      );
      if (c.showControl) {
        expect(spyFinder, findsOneWidget);
        final spy = tester.widget<CtActionTextButton>(spyFinder);
        expect(spy.enabled, c.enabled);
        await tester.ensureVisible(spyFinder);
        await tester.pump();
      } else {
        expect(spyFinder, findsNothing);
      }

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }
}
