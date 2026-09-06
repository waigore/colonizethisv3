// Pins MAP20001 Sail / Move host enablement (Refs #4735).

import 'package:colonizethis_app/features/game/flame/map_state/province_overlay_sail_move_overlay_controls.dart';
import 'package:colonizethis_app/features/game/flame/overlays/province_detail_overlay_host_support_sail_move.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoHumanPlayerViewForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'province_naval_mission_action_state_fixtures.dart';

void main() {
  suppressLogsForTests();

  final l10n = AppLocalizationsEn();

  testWidgets('host enables Sail / Move for sea-zone occupancy', (tester) async {
    late ProvinceOverlaySailMoveOverlayControls controls;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            controls = buildProvinceOverlaySailMoveOverlayControls(
              context: context,
              game: gameWith(fleets: [atSeaFleet()]),
              region: demoRegionForOverlay,
              humanPlayerId: human,
              playerView: demoHumanPlayerViewForOverlay,
              displayId: 'oldWorld|$sea',
              mapData: null,
              canMutateViaUi: true,
              omniscientDetail: true,
              bus: AppEventBus.create(),
              isSeaZone: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(controls.showSailMove, isTrue);
    expect(controls.sailMoveEnabled, isTrue);
    expect(controls.onSailMoveTap, isNotNull);
    expect(controls.sailMoveTooltip, l10n.naval_mission_effect_sail);
  });

  testWidgets('host hides Sail / Move when observe or Home Fleet only', (
    tester,
  ) async {
    final home = Fleet(
      id: homeFleetIdFor(human),
      ownerId: human,
      inPortAtProvinceId: owned,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    late ProvinceOverlaySailMoveOverlayControls observe;
    late ProvinceOverlaySailMoveOverlayControls homeOnly;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            observe = buildProvinceOverlaySailMoveOverlayControls(
              context: context,
              game: gameWith(fleets: [atSeaFleet()]),
              region: demoRegionForOverlay,
              humanPlayerId: human,
              playerView: demoHumanPlayerViewForOverlay,
              displayId: 'oldWorld|$sea',
              mapData: null,
              canMutateViaUi: false,
              omniscientDetail: true,
              bus: AppEventBus.create(),
              isSeaZone: true,
            );
            homeOnly = buildProvinceOverlaySailMoveOverlayControls(
              context: context,
              game: gameWith(fleets: [home]),
              region: demoRegionForOverlay,
              humanPlayerId: human,
              playerView: demoHumanPlayerViewForOverlay,
              displayId: owned,
              mapData: null,
              canMutateViaUi: true,
              omniscientDetail: true,
              bus: AppEventBus.create(),
              isSeaZone: false,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(observe.showSailMove, isFalse);
    expect(homeOnly.showSailMove, isFalse);
  });

  testWidgets('host enables Sail / Move for owned in-port fleet', (tester) async {
    final inPort = Fleet(
      id: 'f_port',
      ownerId: human,
      inPortAtProvinceId: owned,
      regionId: 'oldWorld',
      shipTypeIds: const ['carrack'],
    );
    late ProvinceOverlaySailMoveOverlayControls controls;
    await tester.pumpWidget(
      buildAppShell(
        localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        child: Builder(
          builder: (context) {
            controls = buildProvinceOverlaySailMoveOverlayControls(
              context: context,
              game: gameWith(fleets: [inPort]),
              region: demoRegionForOverlay,
              humanPlayerId: human,
              playerView: demoHumanPlayerViewForOverlay,
              displayId: owned,
              mapData: null,
              canMutateViaUi: true,
              omniscientDetail: true,
              bus: AppEventBus.create(),
              isSeaZone: false,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(controls.showSailMove, isTrue);
    expect(controls.sailMoveEnabled, isTrue);
  });
}
