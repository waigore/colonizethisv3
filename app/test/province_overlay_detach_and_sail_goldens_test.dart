// Visual goldens for MAP20001 Naval Detach and sail (Refs #4448).
// SPEC/ui/province-sea-zone-detail-overlay.md § States and variants.

import 'package:colonizethis_app/features/game/flame/map_state/province_detach_and_sail_overlay_controls.dart';
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

class _DetachSailGoldenCase {
  const _DetachSailGoldenCase({
    required this.name,
    required this.goldenFile,
    required this.showDetachAndSail,
    required this.detachAndSailEnabled,
    this.overlaySize = const Size(460, 680),
    this.surfaceSize = const Size(640, 720),
  });

  final String name;
  final String goldenFile;
  final bool showDetachAndSail;
  final bool detachAndSailEnabled;
  final Size overlaySize;
  final Size surfaceSize;
}

const List<_DetachSailGoldenCase> _cases = [
  _DetachSailGoldenCase(
    name: 'Naval Detach and sail enabled',
    goldenFile: 'goldens/province_overlay_detach_and_sail_enabled.png',
    showDetachAndSail: true,
    detachAndSailEnabled: true,
  ),
  _DetachSailGoldenCase(
    name: 'Naval Detach and sail hidden',
    goldenFile: 'goldens/province_overlay_detach_and_sail_hidden.png',
    showDetachAndSail: false,
    detachAndSailEnabled: false,
  ),
  _DetachSailGoldenCase(
    name: 'Naval Detach and sail 320 dp',
    goldenFile: 'goldens/province_overlay_detach_and_sail_320.png',
    showDetachAndSail: true,
    detachAndSailEnabled: true,
    overlaySize: Size(320, 680),
  ),
];

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  for (final c in _cases) {
    testWidgets('golden: ${c.name} (Refs #4448)', (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: c.surfaceSize);
      configureGoldenView(
        tester,
        physicalSize: c.surfaceSize,
        devicePixelRatio: 1.0,
      );

      final boundaryKey = ValueKey<String>('province_overlay_${c.name}_golden');
      final game = demoGameForOverlay;
      final humanId = game.players.first.id;

      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          child: SizedBox(
            width: c.overlaySize.width,
            height: c.overlaySize.height,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: humanId,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              detachAndSail: ProvinceDetachAndSailOverlayControls(
                showDetachAndSail: c.showDetachAndSail,
                detachAndSailEnabled: c.detachAndSailEnabled,
                detachAndSailTooltip: c.detachAndSailEnabled
                    ? l10n.provinceOverlay_detachAndSailTooltip
                    : '',
                onDetachAndSailTap: () {},
              ),
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      final navalHeader = find.text(
        l10n.provinceOverlay_sectionNaval.toUpperCase(),
      );
      expect(navalHeader, findsOneWidget);
      await tester.ensureVisible(navalHeader);
      await tester.pump();

      final actionFinder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_detachAndSailAction,
      );
      if (c.showDetachAndSail) {
        expect(actionFinder, findsOneWidget);
        final action = tester.widget<CtActionTextButton>(actionFinder);
        expect(action.enabled, c.detachAndSailEnabled);
        expect(action.onPressed, isNotNull);
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
