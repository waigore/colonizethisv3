// Pump harness for MAP20001 naval mission overlay control pins (Refs #4413).

import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Future<void> pumpNavalMissionOverlay(
  WidgetTester tester, {
  required Game game,
  required String humanId,
  ProvinceNavalMissionOverlayControls navalMission =
      ProvinceNavalMissionOverlayControls.hidden,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: SizedBox(
        width: 460,
        height: 680,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: demoRegionForOverlay,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          humanPlayerId: humanId,
          playerView: demoHumanPlayerViewForOverlay,
          omniscientDetail: true,
          navalMission: navalMission,
          blockadeStatus: navalMission.blockadeStatus,
          onClose: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Game demoNavalMissionOverlayGame() => demoGameForOverlay;
