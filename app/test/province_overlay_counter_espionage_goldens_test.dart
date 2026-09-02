// Visual goldens for MAP20001 Civilian Counter-espionage variants (Refs #4528).
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
import 'widgetbook_test_harness.dart' show revealProvinceOverlayWideSection;

class _CounterEspionageGoldenCase {
  const _CounterEspionageGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showControl,
    required this.enabled,
    this.tooltip = '',
    this.gist = '',
  });

  final String name;
  final String goldenFile;
  final bool showControl;
  final bool enabled;
  final String tooltip;
  final String gist;
}

const List<_CounterEspionageGoldenCase> _cases = [
  _CounterEspionageGoldenCase(
    name: 'Civilian Counter-espionage enabled',
    goldenFile: 'goldens/province_overlay_counter_espionage_enabled.png',
    showControl: true,
    enabled: true,
    gist: 'Protects the whole realm, not only this province.',
  ),
  _CounterEspionageGoldenCase(
    name: 'Civilian Counter-espionage disabled',
    goldenFile: 'goldens/province_overlay_counter_espionage_disabled.png',
    showControl: true,
    enabled: false,
    tooltip: 'No idle Spy can take this post.',
  ),
  _CounterEspionageGoldenCase(
    name: 'Civilian Counter-espionage hidden',
    goldenFile: 'goldens/province_overlay_counter_espionage_hidden.png',
    showControl: false,
    enabled: false,
  ),
];

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4528)', (WidgetTester tester) async {
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
              counterEspionage: (
                showControl: c.showControl,
                enabled: c.enabled,
                tooltip: c.tooltip,
                gist: c.gist,
                onTap: () {},
              ),
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);
      expect(tester.takeException(), isNull);

      await revealProvinceOverlayWideSection(
        tester,
        sectionTitle: l10n.provinceOverlay_sectionCivilian,
      );

      final actionFinder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_counterEspionageAction,
      );
      if (c.showControl) {
        expect(actionFinder, findsOneWidget);
        final action = tester.widget<CtActionTextButton>(actionFinder);
        expect(action.enabled, c.enabled);
        await tester.ensureVisible(actionFinder);
        await tester.pump();
      } else {
        expect(actionFinder, findsNothing);
      }

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }
}
