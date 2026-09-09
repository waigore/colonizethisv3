// MAP20001 Train {type} overlay pins (Refs #4752).

import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_control.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_test_harness.dart';
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

  testWidgets(
    'Train Explorer is enabled beside disabled Explore when no Explorers',
    (tester) async {
      var opened = 0;
      await pumpProvinceOverlayAtDarkTheme(
        tester,
        game: demoGameForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        showExploreActionIcon: true,
        exploreActionEnabled: false,
        onTrainCivilianTap: () => opened++,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsOneWidget);
      expect(find.text('Train Explorer'), findsOneWidget);
      expect(
        find.textContaining('appears at your capital after Next turn'),
        findsOneWidget,
      );
      await tester.tap(find.text('Train Explorer'));
      await tester.pump();
      expect(opened, 1);
    },
  );

  testWidgets('Train Explorer is omitted when Explorer units exist', (
    tester,
  ) async {
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: demoGameForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      showExploreActionIcon: true,
      exploreActionEnabled: true,
      onExploreWithExplorerTap: () {},
      onTrainCivilianTap: () {},
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsNothing);
  });

  testWidgets('Train Explorer is omitted when Consulate gate also applies', (
    tester,
  ) async {
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: _tribeOwnedDemoGame(),
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      showExploreActionIcon: true,
      exploreActionEnabled: false,
      onTrainCivilianTap: () {},
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsNothing);
  });

  testWidgets('Train Explorer is omitted without a train tap callback', (
    tester,
  ) async {
    await pumpProvinceOverlayAtDarkTheme(
      tester,
      game: demoGameForOverlay,
      displayId: sampleProvinceIdForOverlay,
      selectedTileKey: sampleTileKeyForProvinceOverlay,
      showExploreActionIcon: true,
      exploreActionEnabled: false,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(kProvinceOverlayTrainExplorerKey), findsNothing);
  });
}
