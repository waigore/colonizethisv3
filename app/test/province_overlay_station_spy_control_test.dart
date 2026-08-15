// Overlay-level MAP20001 Civilian Station spy control (Refs #4439).
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md

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

import 'app_shell_harness.dart';

Widget _overlay({
  required bool showControl,
  required bool enabled,
  String tooltip = '',
  VoidCallback? onTap,
}) {
  final game = demoGameForOverlay;
  return buildAppShell(
    viewport: const Size(800, 640),
    child: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        omniscientDetail: true,
        stationSpy: (
          showControl: showControl,
          enabled: enabled,
          tooltip: tooltip,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  testWidgets(
    'enabled Station spy fires onTap even with empty-looking roster',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _overlay(
          showControl: true,
          enabled: true,
          tooltip: l10n.provinceOverlay_stationSpyAction,
          onTap: () => taps++,
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_stationSpyAction,
      );
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(taps, 1);
    },
  );

  testWidgets('disabled Station spy does not fire onTap', (tester) async {
    await tester.pumpWidget(
      _overlay(
        showControl: true,
        enabled: false,
        tooltip: l10n.provinceOverlay_stationSpyDisabledNoIdleSpyTooltip,
      ),
    );
    await tester.pumpAndSettle();
    final action = tester.widget<CtActionTextButton>(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_stationSpyAction,
      ),
    );
    expect(action.enabled, isFalse);
    expect(
      action.tooltip,
      l10n.provinceOverlay_stationSpyDisabledNoIdleSpyTooltip,
    );
    expect(action.onPressed, isNull);
  });

  testWidgets('hidden Station spy is absent', (tester) async {
    await tester.pumpWidget(_overlay(showControl: false, enabled: false));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_stationSpyAction,
      ),
      findsNothing,
    );
  });
}
