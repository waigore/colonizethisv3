// Pump/assert helpers for blockade_capital_link_ui_test.dart (Refs #4680).

import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_tile_connectivity.dart'
    show ProvinceTileConnectivityDisplay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_tile_details.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_target_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_mission_goldens_test_support.dart';
import 'panel_test_fixtures.dart';

const disconnectedTileConnectivity = ProvinceTileConnectivityDisplay(
  capitalConnected: false,
  extractionEffective: 0,
  extractionFull: 3,
);

const connectedTileConnectivity = ProvinceTileConnectivityDisplay(
  capitalConnected: true,
  extractionEffective: 1,
  extractionFull: 1,
);

Future<void> pumpBlockadeNavalSection(
  WidgetTester tester, {
  ProvinceBlockadeStatus? blockadeStatus,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: Builder(
        builder: (context) {
          return buildNavalSection(
            l10n: appL10n(context),
            game: buildNavalMissionMenuPeacetimeGame(),
            fleets: const [],
            humanPlayerId: navalMissionGoldenHumanId,
            draftOrders: const Orders(),
            blockadeStatus: blockadeStatus ?? ProvinceBlockadeStatus.none,
          );
        },
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpBlockadeTargetDialog(
  WidgetTester tester, {
  required Game game,
  required String enemyCap,
}) async {
  final fleet = game.worldState.fleets.single;
  await tester.pumpWidget(
    buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: NavalMissionTargetDialog(
        game: game,
        mission: FleetMission.blockade,
        fleet: fleet,
        targetProvinceIds: [enemyCap],
        humanPlayerId: navalMissionGoldenHumanId,
        initialTargetProvinceId: enemyCap,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> blockadeTileDetailsLines({
  required AppLocalizationsEn l10n,
  required Game game,
  required String provinceId,
  required ProvinceTileConnectivityDisplay tileConnectivity,
  ProvinceBlockadeStatus? blockadeStatus,
  int roadLevel = 0,
}) {
  return provinceTileDetailsLines(
    l10n: l10n,
    game: game,
    humanPlayerId: navalMissionGoldenHumanId,
    provinceId: provinceId,
    roadLevel: roadLevel,
    tileConnectivity: tileConnectivity,
    blockadeStatus: blockadeStatus ?? ProvinceBlockadeStatus.none,
  );
}

Game blockadeTileDetailsGame({
  required String id,
  required List<Province> oldWorldProvinces,
}) {
  return buildPanelTestGame(
    id: id,
    players: const [
      Player(
        id: navalMissionGoldenHumanId,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: 'oldWorld|cap1',
      ),
    ],
    oldWorldProvinces: oldWorldProvinces,
  );
}
