// Goldens for MAP30002 More dialog. SPEC/ui/tile-context-radial.md (Refs #4440, #4570).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

List<TileRadialSpokeView> _wedges({bool exploreEnabled = true}) {
  return [
    TileRadialSpokeView(
      action: TileRadialCatalogAction.explore,
      enabled: exploreEnabled,
      label: 'Explore',
      tooltip: 'Explore with explorer',
    ),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.prospect,
      enabled: true,
      label: 'Prospect',
      tooltip: 'Prospect with explorer',
    ),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.buildImprovement,
      enabled: true,
      label: 'Build improvement',
      tooltip: 'Build improvement',
    ),
  ];
}

List<TileRadialSpokeView> _moreBuildRoadOverflow() {
  return const [
    TileRadialSpokeView(
      action: TileRadialCatalogAction.buildRoad,
      enabled: true,
      label: 'Build road',
      tooltip: 'Build road',
    ),
    TileRadialSpokeView(
      action: TileRadialCatalogAction.upgradeTown,
      enabled: false,
      label: 'Upgrade town',
      tooltip: 'Upgrade town disabled',
    ),
  ];
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: More dialog empty remainder', (tester) async {
    final key = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: key,
      physicalSize: const Size(400, 400),
      includeLocalizations: true,
      center: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: const TileMoreActionsDialog(
        placeLine: 'Place: Wessex',
        remainder: [],
        onAction: _noopAction,
        onProvinceDetails: _noop,
      ),
    );
    await pumpSettleCapped(tester);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_more_actions_empty.png'),
    );
  });

  testWidgets('golden: More dialog 320 dp', (tester) async {
    final key = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: key,
      physicalSize: const Size(320, 640),
      includeLocalizations: true,
      center: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: TileMoreActionsDialog(
        placeLine: 'Place: Wessex',
        remainder: _wedges(),
        onAction: _noopAction,
        onProvinceDetails: _noop,
      ),
    );
    await pumpSettleCapped(tester);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_more_actions_320.png'),
    );
  });

  testWidgets(
    'golden: More remainder Build road overflow + Province details (AC-4)',
    (tester) async {
      final key = GlobalKey();
      await pumpGoldenHost(
        tester,
        boundaryKey: key,
        physicalSize: const Size(400, 400),
        includeLocalizations: true,
        center: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: TileMoreActionsDialog(
          placeLine: 'Place: Wessex',
          remainder: _moreBuildRoadOverflow(),
          onAction: _noopAction,
          onProvinceDetails: _noop,
        ),
      );
      await pumpSettleCapped(tester);
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/tile_more_actions_build_road_overflow.png'),
      );
    },
  );
}

void _noop() {}

void _noopAction(TileRadialCatalogAction action) {}
