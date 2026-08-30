// Overlay-level MAP20001 Civilian Counter-espionage control (Refs #4528).
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
  String gist = '',
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
        counterEspionage: (
          showControl: showControl,
          enabled: enabled,
          tooltip: tooltip,
          gist: gist,
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
    'enabled Counter-espionage fires onTap and shows whole-realm gist',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _overlay(
          showControl: true,
          enabled: true,
          tooltip: l10n.provinceOverlay_counterEspionageOneSpyTooltip,
          gist: l10n.provinceOverlay_counterEspionageGist,
          onTap: () => taps++,
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_counterEspionageAction,
      );
      expect(button, findsOneWidget);
      expect(
        find.text(l10n.provinceOverlay_counterEspionageGist),
        findsOneWidget,
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(taps, 1);
    },
  );

  testWidgets('disabled Counter-espionage does not fire onTap', (tester) async {
    await tester.pumpWidget(
      _overlay(
        showControl: true,
        enabled: false,
        tooltip: l10n.provinceOverlay_counterEspionageDisabledNoIdleSpyTooltip,
      ),
    );
    await tester.pumpAndSettle();
    final action = tester.widget<CtActionTextButton>(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_counterEspionageAction,
      ),
    );
    expect(action.enabled, isFalse);
    expect(
      action.tooltip,
      l10n.provinceOverlay_counterEspionageDisabledNoIdleSpyTooltip,
    );
    expect(action.onPressed, isNull);
  });

  testWidgets('hidden Counter-espionage is absent', (tester) async {
    await tester.pumpWidget(_overlay(showControl: false, enabled: false));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_counterEspionageAction,
      ),
      findsNothing,
    );
  });
}
