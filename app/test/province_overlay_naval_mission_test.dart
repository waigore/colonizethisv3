// Pins MAP20001 Naval Blockade/Beachhead overlay controls (Refs #4413).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_naval_mission.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_civilian_naval_sections.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_mission_goldens_test_support.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  final game = demoGameForOverlay;
  final humanId = game.players.first.id;

  Future<void> pumpOverlay(
    WidgetTester tester, {
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

  testWidgets('hidden controls omit Blockade and Beachhead', (tester) async {
    await pumpOverlay(tester);
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_blockadeAction,
      ),
      findsNothing,
    );
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_beachheadAction,
      ),
      findsNothing,
    );
  });

  testWidgets('enabled controls show Blockade and Beachhead', (tester) async {
    await pumpOverlay(
      tester,
      navalMission: ProvinceNavalMissionOverlayControls(
        showBlockade: true,
        blockadeEnabled: true,
        blockadeTooltip: l10n.naval_mission_effect_blockade,
        onBlockadeTap: () {},
        showBeachhead: true,
        beachheadEnabled: true,
        beachheadTooltip: l10n.naval_mission_effect_beachhead,
        onBeachheadTap: () {},
      ),
    );
    final navalHeader = find.text(
      l10n.provinceOverlay_sectionNaval.toUpperCase(),
    );
    await tester.ensureVisible(navalHeader);
    await tester.pump();
    final blockade = tester.widget<CtActionTextButton>(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_blockadeAction,
      ),
    );
    expect(blockade.enabled, isTrue);
    final beachhead = tester.widget<CtActionTextButton>(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_beachheadAction,
      ),
    );
    expect(beachhead.enabled, isTrue);
    expect(beachhead.tooltip, l10n.naval_mission_effect_beachhead);
    expect(
      (beachhead.tooltip ?? '').toLowerCase(),
      isNot(contains('this turn')),
    );
  });

  testWidgets('fogged roster still shows mission actions', (tester) async {
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return buildNavalSection(
              l10n: appL10n(context),
              game: game,
              fleets: const [],
              humanPlayerId: humanId,
              draftOrders: const Orders(),
              rosterObfuscated: true,
              navalMission: ProvinceNavalMissionOverlayControls(
                showBlockade: true,
                blockadeEnabled: true,
                blockadeTooltip: l10n.naval_mission_effect_blockade,
                onBlockadeTap: () {},
                showBeachhead: true,
                beachheadEnabled: true,
                beachheadTooltip: l10n.naval_mission_effect_beachhead,
                onBeachheadTap: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text(l10n.provinceOverlay_unknown), findsOneWidget);
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_blockadeAction,
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_beachheadAction,
      ),
      findsOneWidget,
    );
  });

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

      await pumpOverlay(tester, navalMission: controls);
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
