// Pins MAP20001 Naval Transfer to Home Fleet overlay (Refs #4625).

import 'package:colonizethis_app/core/services/game_service/game_service.dart'
    show GameMapData;
import 'package:colonizethis_app/features/game/flame/map_state/province_transfer_to_home_fleet_overlay_controls.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_transfer_home.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/overlay_transfer_to_home_fleet_flow.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/home_fleet_transfer_eligibility.dart';
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
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_units_panel_test_support.dart';

GameMapData _adjacentSeaMap() {
  return (
    combinedTopology: const MapTopology(
      edges: [TopologyEdge(id1: 'oldWorld|cap1', id2: 'oldWorld|sea1')],
    ),
    tileMapByRegion: const {},
    topologyByRegion: const {},
    warpLinks: null,
  );
}

Fleet _inPortPeer(String humanId, String id) {
  return Fleet(
    id: id,
    ownerId: humanId,
    regionId: 'oldWorld',
    inPortAtProvinceId: 'oldWorld|cap1',
    ships: [ShipInstance(id: '${id}_s', typeId: 'carrack')],
  );
}

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();
  final game = demoGameForOverlay;
  final humanId = game.players.first.id;

  Future<void> pumpOverlay(
    WidgetTester tester, {
    ProvinceTransferToHomeFleetOverlayControls transfer =
        ProvinceTransferToHomeFleetOverlayControls.hidden,
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
            transferToHomeFleet: transfer,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('hidden controls omit Transfer to Home Fleet', (tester) async {
    await pumpOverlay(tester);
    expect(
      find.widgetWithText(
        CtActionTextButton,
        l10n.provinceOverlay_transferToHomeFleetAction,
      ),
      findsNothing,
    );
  });

  testWidgets('enabled control shows Transfer and invokes tap', (tester) async {
    var tapped = false;
    await pumpOverlay(
      tester,
      transfer: ProvinceTransferToHomeFleetOverlayControls(
        showTransferToHomeFleet: true,
        transferToHomeFleetEnabled: true,
        transferToHomeFleetTooltip:
            l10n.provinceOverlay_transferToHomeFleetTooltip,
        onTransferToHomeFleetTap: () => tapped = true,
      ),
    );
    final navalHeader = find.text(
      l10n.provinceOverlay_sectionNaval.toUpperCase(),
    );
    await tester.ensureVisible(navalHeader);
    await tester.pump();
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_transferToHomeFleetAction,
    );
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    expect(tapped, isTrue);
  });

  testWidgets('disabled control is visible and does not tap-open', (
    tester,
  ) async {
    var tapped = false;
    await pumpOverlay(
      tester,
      transfer: ProvinceTransferToHomeFleetOverlayControls(
        showTransferToHomeFleet: true,
        transferToHomeFleetEnabled: false,
        transferToHomeFleetTooltip:
            l10n.provinceOverlay_transferToHomeFleetDisabledTooltip,
        onTransferToHomeFleetTap: () => tapped = true,
      ),
    );
    final finder = find.widgetWithText(
      CtActionTextButton,
      l10n.provinceOverlay_transferToHomeFleetAction,
    );
    expect(finder, findsOneWidget);
    final action = tester.widget<CtActionTextButton>(finder);
    expect(action.enabled, isFalse);
    expect(action.onPressed, isNull);
    expect(tapped, isFalse);
  });

  test('eligibility: in-port at capital qualifies; empty does not', () {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_el',
      displayName: 'Cap',
      peerFleets: [_inPortPeer(playerId, 'peer1')],
    );
    final sources = overlayTransferToHomeSourceFleets(
      game: capitalGame,
      humanPlayerId: playerId,
      displayId: 'oldWorld|cap1',
      isSeaZone: false,
      topology: const MapTopology(),
    );
    expect(sources.map((f) => f.id), ['peer1']);
  });

  test('eligibility: at-sea requires topology adjacency', () {
    const playerId = 'gp_cap';
    final atSea = Fleet(
      id: 'sea_peer',
      ownerId: playerId,
      regionId: 'oldWorld',
      seaZoneId: 'sea1',
      ships: const [ShipInstance(id: 'ss', typeId: 'carrack')],
    );
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_sea',
      displayName: 'Cap',
      peerFleets: [atSea],
    );
    final topology = const MapTopology(
      edges: [TopologyEdge(id1: 'oldWorld|cap1', id2: 'oldWorld|sea1')],
    );
    expect(
      overlayTransferToHomeSourceFleets(
        game: capitalGame,
        humanPlayerId: playerId,
        displayId: 'oldWorld|sea1',
        isSeaZone: true,
        topology: topology,
      ).map((f) => f.id),
      ['sea_peer'],
    );
    expect(
      overlayTransferToHomeSourceFleets(
        game: capitalGame,
        humanPlayerId: playerId,
        displayId: 'oldWorld|sea_other',
        isSeaZone: true,
        topology: topology,
      ),
      isEmpty,
    );
  });

  testWidgets('host enables Transfer on owned capital with in-port source', (
    tester,
  ) async {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_cap_t',
      displayName: 'Cap',
      peerFleets: [_inPortPeer(playerId, 'peer1')],
    );
    late ProvinceTransferToHomeFleetOverlayControls controls;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            controls = buildProvinceTransferToHomeFleetOverlayControls(
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
    expect(controls.showTransferToHomeFleet, isTrue);
    expect(controls.transferToHomeFleetEnabled, isTrue);
    expect(controls.onTransferToHomeFleetTap, isNotNull);
  });

  testWidgets('host hides Transfer when observe; disables with no source', (
    tester,
  ) async {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_cap_hide_t',
      displayName: 'Cap',
      peerFleets: const [],
    );
    late ProvinceTransferToHomeFleetOverlayControls observe;
    late ProvinceTransferToHomeFleetOverlayControls noSource;
    late ProvinceTransferToHomeFleetOverlayControls farSea;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            observe = buildProvinceTransferToHomeFleetOverlayControls(
              context: context,
              game: capitalGame,
              humanPlayerId: playerId,
              displayId: 'oldWorld|cap1',
              mapData: null,
              canMutateViaUi: false,
              bus: AppEventBus.create(),
              isSeaZone: false,
            );
            noSource = buildProvinceTransferToHomeFleetOverlayControls(
              context: context,
              game: capitalGame,
              humanPlayerId: playerId,
              displayId: 'oldWorld|cap1',
              mapData: null,
              canMutateViaUi: true,
              bus: AppEventBus.create(),
              isSeaZone: false,
            );
            farSea = buildProvinceTransferToHomeFleetOverlayControls(
              context: context,
              game: capitalGame,
              humanPlayerId: playerId,
              displayId: 'oldWorld|sea_far',
              mapData: _adjacentSeaMap(),
              canMutateViaUi: true,
              bus: AppEventBus.create(),
              isSeaZone: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(observe.showTransferToHomeFleet, isFalse);
    expect(noSource.showTransferToHomeFleet, isTrue);
    expect(noSource.transferToHomeFleetEnabled, isFalse);
    expect(farSea.showTransferToHomeFleet, isFalse);
  });

  testWidgets('host enables Transfer on adjacent sea with at-sea source', (
    tester,
  ) async {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_sea_t',
      displayName: 'Cap',
      peerFleets: [
        Fleet(
          id: 'sea_peer',
          ownerId: playerId,
          regionId: 'oldWorld',
          seaZoneId: 'sea1',
          ships: const [ShipInstance(id: 'ss', typeId: 'carrack')],
        ),
      ],
    );
    late ProvinceTransferToHomeFleetOverlayControls controls;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            controls = buildProvinceTransferToHomeFleetOverlayControls(
              context: context,
              game: capitalGame,
              humanPlayerId: playerId,
              displayId: 'oldWorld|sea1',
              mapData: _adjacentSeaMap(),
              canMutateViaUi: true,
              bus: AppEventBus.create(),
              isSeaZone: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(controls.showTransferToHomeFleet, isTrue);
    expect(controls.transferToHomeFleetEnabled, isTrue);
  });

  testWidgets('single-source flow opens DLG40001', (tester) async {
    const playerId = 'gp_cap';
    final capitalGame = buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_flow',
      displayName: 'Cap',
      peerFleets: [_inPortPeer(playerId, 'peer1')],
    );
    final home = capitalGame.fleetById(homeFleetIdFor(playerId))!;
    final source = capitalGame.worldState.fleets.firstWhere(
      (f) => f.id == 'peer1',
    );
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showOverlayTransferToHomeFleetFlow(
                  context: context,
                  game: capitalGame,
                  humanPlayerId: playerId,
                  bus: AppEventBus.create(),
                  homeFleet: home,
                  sourceFleets: [source],
                  cargo: const HomeFleetCargoSummary(used: 0, capacity: 0),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.naval_transferToHome_dialogTitle), findsOneWidget);
  });
}
