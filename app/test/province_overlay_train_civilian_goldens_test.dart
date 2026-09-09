// Pixel goldens for MAP20001 Train {type} variants (Refs #4752).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdNationalBureaucracy;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'province_overlay_test_harness_build.dart';
import 'widget_test_assets.dart';

Game _tribeOwnedDemoGame() {
  final base = demoGameForOverlay;
  const ownerId = 'tribe_gate';
  final ow = base.worldState.oldWorld;
  final provinces = [
    for (final p in ow.provinces)
      if (p.id == sampleProvinceIdForOverlay)
        p.copyWith(ownerId: ownerId)
      else
        p,
  ];
  return base.copyWith(
    worldState: base.worldState.copyWith(
      oldWorld: RegionData(provinces: provinces, units: ow.units),
    ),
    tribes: [
      ...base.tribes,
      const Tribe(id: ownerId, displayName: 'Gate Tribe'),
    ],
  );
}

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(preloadNinePatchImage);

  Future<void> capture({
    required WidgetTester tester,
    required String slug,
    required Size size,
    required Widget child,
  }) async {
    final key = Key('train_civilian_$slug');
    await pumpGoldenHost(
      tester,
      boundaryKey: key,
      child: child,
      physicalSize: size,
      includeLocalizations: true,
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/province_overlay_train_civilian_$slug.png'),
    );
  }

  testWidgets('Train Explorer missing-unit sole-cause golden', (tester) async {
    await capture(
      tester: tester,
      slug: 'explorer_enabled',
      size: const Size(400, 520),
      child: buildProvinceOverlayDarkThemeShell(
        game: demoGameForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        showExploreActionIcon: true,
        onTrainCivilianTap: () {},
      ),
    );
  });

  testWidgets('Train Explorer hidden when units exist golden', (tester) async {
    await capture(
      tester: tester,
      slug: 'explorer_units_exist',
      size: const Size(400, 520),
      child: buildProvinceOverlayDarkThemeShell(
        game: demoGameForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        showExploreActionIcon: true,
        exploreActionEnabled: true,
        onExploreWithExplorerTap: () {},
        onTrainCivilianTap: () {},
      ),
    );
  });

  testWidgets('Train Explorer omitted on Consulate both-applied golden', (
    tester,
  ) async {
    await capture(
      tester: tester,
      slug: 'explorer_consulate_omit',
      size: const Size(400, 520),
      child: buildProvinceOverlayDarkThemeShell(
        game: _tribeOwnedDemoGame(),
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        showExploreActionIcon: true,
        onTrainCivilianTap: () {},
      ),
    );
  });

  testWidgets('Train Explorer 320 dp wrap golden', (tester) async {
    await capture(
      tester: tester,
      slug: 'explorer_320dp',
      size: const Size(320, 560),
      child: SizedBox(
        width: 320,
        child: buildProvinceOverlayDarkThemeShell(
          game: demoGameForOverlay,
          displayId: sampleProvinceIdForOverlay,
          selectedTileKey: sampleTileKeyForProvinceOverlay,
          showExploreActionIcon: true,
          onTrainCivilianTap: () {},
          viewport: const Size(320, 560),
        ),
      ),
    );
  });

  testWidgets('Train Builder Upgrade town missing-unit golden', (tester) async {
    final base = demoGameForOverlay;
    final human = base.players.first;
    final game = base.copyWith(
      players: [
        human.copyWith(
          techUnlocked: {
            ...?human.techUnlocked,
            kTechIdNationalBureaucracy: true,
          },
        ),
        ...base.players.skip(1),
      ],
    );
    await capture(
      tester: tester,
      slug: 'builder_upgrade_town',
      size: const Size(400, 520),
      child: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        showUpgradeTownControl: true,
        upgradeTownHasBuilderUnits: false,
        upgradeTownTargetTileKey: sampleTileKeyForProvinceOverlay,
        inlineActionCallbacks: (
          onExploreWithExplorerTap: null,
          onProspectWithExplorerTap: null,
          onBuildImprovementTap: null,
          onBuildRoadTap: null,
          onBuildFortTap: null,
          onBuildPortTap: null,
          onBuildRailroadTap: null,
          onPurchaseLandTap: null,
          onTrainCivilianTap: () {},
        ),
      ),
    );
  });
}
