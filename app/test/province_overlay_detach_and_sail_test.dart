// Pins MAP20001 Naval Detach and sail overlay controls (Refs #4448).

import 'package:colonizethis_app/features/game/flame/map_state/province_detach_and_sail_overlay_controls.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_detach_sail.dart';
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
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  final game = demoGameForOverlay;
  final humanId = game.players.first.id;

  Future<void> pumpOverlay(
    WidgetTester tester, {
    ProvinceDetachAndSailOverlayControls detachAndSail =
        ProvinceDetachAndSailOverlayControls.hidden,
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
            detachAndSail: detachAndSail,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hidden controls omit Detach and sail', (tester) async {
    await pumpOverlay(tester);
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_detachAndSailAction,
      ),
      findsNothing,
    );
  });

  testWidgets('enabled control shows Detach and sail and invokes tap', (
    tester,
  ) async {
    var tapped = false;
    await pumpOverlay(
      tester,
      detachAndSail: ProvinceDetachAndSailOverlayControls(
        showDetachAndSail: true,
        detachAndSailEnabled: true,
        detachAndSailTooltip: l10n.provinceOverlay_detachAndSailTooltip,
        onDetachAndSailTap: () => tapped = true,
      ),
    );
    final navalHeader = find.text(
      l10n.provinceOverlay_sectionNaval.toUpperCase(),
    );
    await tester.ensureVisible(navalHeader);
    await tester.pump();
    final actionFinder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_detachAndSailAction,
    );
    await tester.ensureVisible(actionFinder);
    await tester.pump();
    final action = tester.widget<CtActionTextButton>(actionFinder);
    expect(action.enabled, isTrue);
    await tester.tap(actionFinder);
    expect(tapped, isTrue);
  });

  testWidgets('host shows Detach and sail on owned capital with ships', (
    tester,
  ) async {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_cap',
      displayName: 'Cap',
      peerFleets: const [],
    );
    late ProvinceDetachAndSailOverlayControls controls;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            controls = buildProvinceDetachAndSailOverlayControls(
              context: context,
              game: capitalGame,
              humanPlayerId: playerId,
              displayId: 'oldWorld|cap1',
              mapData: null,
              canMutateViaUi: true,
              bus: AppEventBus.create(),
              isSeaZone: false,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(controls.showDetachAndSail, isTrue);
    expect(controls.detachAndSailEnabled, isTrue);
    expect(controls.onDetachAndSailTap, isNotNull);
  });

  testWidgets('host hides Detach and sail when observe or sea-zone', (
    tester,
  ) async {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_cap_hide',
      displayName: 'Cap',
      peerFleets: const [],
    );
    late ProvinceDetachAndSailOverlayControls observe;
    late ProvinceDetachAndSailOverlayControls sea;
    late ProvinceDetachAndSailOverlayControls emptyHome;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            observe = buildProvinceDetachAndSailOverlayControls(
              context: context,
              game: capitalGame,
              humanPlayerId: playerId,
              displayId: 'oldWorld|cap1',
              mapData: null,
              canMutateViaUi: false,
              bus: AppEventBus.create(),
              isSeaZone: false,
            );
            sea = buildProvinceDetachAndSailOverlayControls(
              context: context,
              game: capitalGame,
              humanPlayerId: playerId,
              displayId: 'oldWorld|cap1',
              mapData: null,
              canMutateViaUi: true,
              bus: AppEventBus.create(),
              isSeaZone: true,
            );
            emptyHome = buildProvinceDetachAndSailOverlayControls(
              context: context,
              game: buildNavalPanelCapitalHomeAndPeersGame(
                humanId: playerId,
                gameId: 'g_empty',
                displayName: 'Empty',
                peerFleets: const [],
                homeShips: const [],
              ),
              humanPlayerId: playerId,
              displayId: 'oldWorld|cap1',
              mapData: null,
              canMutateViaUi: true,
              bus: AppEventBus.create(),
              isSeaZone: false,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(observe.showDetachAndSail, isFalse);
    expect(sea.showDetachAndSail, isFalse);
    expect(emptyHome.showDetachAndSail, isFalse);
  });
}
