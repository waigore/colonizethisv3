// Visual goldens for MAP20001 Naval Blockade / Beachhead variants (Refs #4413).
// SPEC/ui/province-sea-zone-detail-overlay.md § States and variants.

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/map_state/province_naval_mission_action_state.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_blockade_status_support.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_naval_mission.dart';
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
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'naval_mission_goldens_test_support.dart';
import 'province_overlay_naval_mission_goldens_cases.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  for (final c in navalMissionGoldenCases) {
    testWidgets('golden: ${c.name} (Refs #4413)', (WidgetTester tester) async {
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
              navalMission: ProvinceNavalMissionOverlayControls(
                showBlockade: c.showBlockade,
                blockadeEnabled: c.blockadeEnabled,
                blockadeTooltip: c.blockadeTooltip,
                onBlockadeTap: () {},
                showBeachhead: c.showBeachhead,
                beachheadEnabled: c.beachheadEnabled,
                beachheadTooltip: c.beachheadTooltip,
                onBeachheadTap: () {},
                blockadeStatus: c.blockadeStatus,
              ),
              blockadeStatus: c.blockadeStatus,
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

      final blockadeFinder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_blockadeAction,
      );
      if (c.showBlockade) {
        expect(blockadeFinder, findsOneWidget);
        final blockade = tester.widget<CtActionTextButton>(blockadeFinder);
        expect(blockade.enabled, c.blockadeEnabled);
        expect(blockade.onPressed, c.blockadeEnabled ? isNotNull : isNull);
        await tester.ensureVisible(blockadeFinder);
        await tester.pump();
      } else {
        expect(blockadeFinder, findsNothing);
      }

      final beachheadFinder = find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_beachheadAction,
      );
      if (c.showBeachhead) {
        expect(beachheadFinder, findsOneWidget);
        final beachhead = tester.widget<CtActionTextButton>(beachheadFinder);
        expect(beachhead.enabled, c.beachheadEnabled);
        expect(beachhead.onPressed, c.beachheadEnabled ? isNotNull : isNull);
        await tester.ensureVisible(beachheadFinder);
        await tester.pump();
      } else {
        expect(beachheadFinder, findsNothing);
      }

      if (c.blockadeStatus != ProvinceBlockadeStatus.none) {
        final statusText =
            c.blockadeStatus == ProvinceBlockadeStatus.capitalBlockaded
            ? l10n.provinceOverlay_underBlockadeCapital
            : l10n.provinceOverlay_underBlockade;
        final statusFinder = find.text(statusText);
        expect(statusFinder, findsOneWidget);
        await tester.ensureVisible(statusFinder);
        await tester.pump();
      }

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(c.goldenFile),
      );
    });
  }

  testWidgets(
    'golden: observe-mode host still shows Under blockade (Refs #4516)',
    (WidgetTester tester) async {
      const surfaceSize = Size(640, 720);
      const overlaySize = Size(460, 680);
      await configureGoldenSurface(tester, size: surfaceSize);
      configureGoldenView(
        tester,
        physicalSize: surfaceSize,
        devicePixelRatio: 1.0,
      );

      const target = 'oldWorld|enemy1';
      final blockadeGame = buildNavalMissionHumanOwnedBlockadedPortGame();
      final GameMapData mapData = (
        combinedTopology: navalMissionWarTopology(),
        tileMapByRegion: const <String, TileMapResult>{},
        topologyByRegion: const <String, MapTopology>{},
        warpLinks: null,
      );
      late ProvinceNavalMissionOverlayControls hostControls;
      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: const ValueKey<String>('unused_host_probe'),
          includeLocalizations: true,
          child: Builder(
            builder: (context) {
              hostControls = buildProvinceNavalMissionOverlayControls(
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
      expect(hostControls.showBlockade, isFalse);
      expect(hostControls.showBeachhead, isFalse);
      expect(hostControls.blockadeStatus, ProvinceBlockadeStatus.portBlockaded);

      const boundaryKey = ValueKey<String>(
        'province_overlay_under_blockade_observe_golden',
      );
      final overlayGame = demoGameForOverlay;
      await tester.pumpWidget(
        wrapGoldenBoundary(
          boundaryKey: boundaryKey,
          includeLocalizations: true,
          child: SizedBox(
            width: overlaySize.width,
            height: overlaySize.height,
            child: ProvinceSeaZoneDetailOverlay(
              game: overlayGame,
              region: demoRegionForOverlay,
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
              humanPlayerId: overlayGame.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              omniscientDetail: true,
              navalMission: hostControls,
              blockadeStatus: hostControls.blockadeStatus,
              onClose: () {},
            ),
          ),
        ),
      );
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      final statusFinder = find.text(l10n.provinceOverlay_underBlockade);
      expect(statusFinder, findsOneWidget);
      await tester.ensureVisible(statusFinder);
      await tester.pump();
      expect(
        find.widgetWithText(
          CtActionTextButton,
          l10n.provinceOverlay_blockadeAction,
        ),
        findsNothing,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/province_overlay_under_blockade_observe.png',
        ),
      );
    },
  );
}
