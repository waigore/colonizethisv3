// Host gating pins for MAP20001 naval mission overlay controls (Refs #4413).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_naval_mission.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoHumanPlayerViewForOverlay, sampleProvinceIdForOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_mission_goldens_test_support.dart';
import 'province_overlay_naval_mission_harness.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  final game = demoNavalMissionOverlayGame();
  final humanId = game.players.first.id;

  testWidgets('canMutateViaUi false hides overlay naval mission controls', (
    tester,
  ) async {
    late ProvinceNavalMissionOverlayControls controls;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            controls = buildProvinceNavalMissionOverlayControls(
              context: context,
              game: game,
              humanPlayerId: humanId,
              playerView: demoHumanPlayerViewForOverlay,
              displayId: sampleProvinceIdForOverlay,
              draftOrders: const Orders(),
              mapData: null,
              canMutateViaUi: false,
              bus: AppEventBus(),
              isSeaZone: false,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(controls.showBlockade, isFalse);
    expect(controls.showBeachhead, isFalse);
  });

  testWidgets(
    'observe-mode host still renders Under blockade in Naval body (Refs #4516)',
    (tester) async {
      const target = 'oldWorld|enemy1';
      final blockadeGame = buildNavalMissionHumanOwnedBlockadedPortGame();
      final GameMapData mapData = (
        combinedTopology: navalMissionWarTopology(),
        tileMapByRegion: const <String, TileMapResult>{},
        topologyByRegion: const <String, MapTopology>{},
        warpLinks: null,
      );
      late ProvinceNavalMissionOverlayControls controls;
      await tester.pumpWidget(
        buildAppShell(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              controls = buildProvinceNavalMissionOverlayControls(
                context: context,
                game: blockadeGame,
                humanPlayerId: navalMissionGoldenHumanId,
                playerView: demoHumanPlayerViewForOverlay,
                displayId: target,
                draftOrders: const Orders(),
                mapData: mapData,
                canMutateViaUi: false,
                bus: AppEventBus(),
                isSeaZone: false,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(controls.showBlockade, isFalse);
      expect(controls.showBeachhead, isFalse);
      expect(controls.blockadeStatus, ProvinceBlockadeStatus.portBlockaded);

      await pumpNavalMissionOverlay(tester, game: game, humanId: humanId,
          navalMission: controls);
      final navalHeader = find.text(
        l10n.provinceOverlay_sectionNaval.toUpperCase(),
      );
      await tester.ensureVisible(navalHeader);
      await tester.pump();
      expect(find.text(l10n.provinceOverlay_underBlockade), findsOneWidget);
      expect(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_blockadeAction,
        ),
        findsNothing,
      );
    },
  );
}
