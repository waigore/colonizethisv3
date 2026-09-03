// Goldens for MAP30001 / MAP30002. SPEC/ui/tile-context-radial.md (Refs #4440, #4570).

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
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

/// Five MAP30001 wedges including Build road / Purchase land (AC-1/2/4).
List<TileRadialSpokeView> _fiveWedgeCatalog() {
  return [
    ..._wedges(),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.buildRoad,
      enabled: true,
      label: 'Build road',
      tooltip: 'Build road',
    ),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.purchaseLand,
      enabled: true,
      label: 'Purchase land',
      tooltip: 'Purchase land',
    ),
  ];
}

/// Town-tile radial including Upgrade town (AC-3 present).
List<TileRadialSpokeView> _upgradeTownPresentWedges() {
  return [
    ..._wedges(),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.upgradeTown,
      enabled: true,
      label: 'Upgrade town',
      tooltip: 'Upgrade town',
    ),
  ];
}

/// Non-town tile: civilian work without Upgrade town (AC-3 absent).
List<TileRadialSpokeView> _upgradeTownAbsentWedges() {
  return [
    ..._wedges(),
    const TileRadialSpokeView(
      action: TileRadialCatalogAction.buildRoad,
      enabled: true,
      label: 'Build road',
      tooltip: 'Build road',
    ),
  ];
}

Future<void> _pumpRadialGolden(
  WidgetTester tester, {
  required GlobalKey boundaryKey,
  required Size physicalSize,
  required List<TileRadialSpokeView> wedges,
  Offset anchor = const Offset(200, 200),
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    center: false,
    scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
    child: ColoredBox(
      color: EditorialMonoclePalette.bgDeep,
      child: TileContextRadial(
        placeLine: 'Place: Wessex',
        wedges: wedges,
        onWedge: (_) {},
        onMore: () {},
        onDismiss: () {},
        anchor: anchor,
      ),
    ),
  );
  await pumpSettleCapped(tester);
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: enabled three wedges', (tester) async {
    final key = GlobalKey();
    await _pumpRadialGolden(
      tester,
      boundaryKey: key,
      physicalSize: const Size(400, 400),
      wedges: _wedges(),
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_enabled.png'),
    );
  });

  testWidgets('golden: Prospect enabled Explore disabled', (tester) async {
    final key = GlobalKey();
    await _pumpRadialGolden(
      tester,
      boundaryKey: key,
      physicalSize: const Size(400, 400),
      wedges: _wedges(exploreEnabled: false),
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_explore_disabled.png'),
    );
  });

  testWidgets('golden: empty catalog More-only', (tester) async {
    final key = GlobalKey();
    await _pumpRadialGolden(
      tester,
      boundaryKey: key,
      physicalSize: const Size(400, 400),
      wedges: const [],
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_empty.png'),
    );
  });

  testWidgets('golden: 320 dp clamp', (tester) async {
    final key = GlobalKey();
    await _pumpRadialGolden(
      tester,
      boundaryKey: key,
      physicalSize: const Size(320, 640),
      wedges: _wedges(),
      anchor: const Offset(16, 16),
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_320.png'),
    );
  });

  testWidgets(
    'golden: five wedges with Build road and Purchase land (AC-1/2/4)',
    (tester) async {
      final key = GlobalKey();
      await _pumpRadialGolden(
        tester,
        boundaryKey: key,
        physicalSize: const Size(400, 400),
        wedges: _fiveWedgeCatalog(),
      );
      await expectLater(
        find.byKey(key),
        matchesGoldenFile('goldens/tile_context_radial_five_wedges.png'),
      );
    },
  );

  testWidgets('golden: Upgrade town present on town tile (AC-3)', (
    tester,
  ) async {
    final key = GlobalKey();
    await _pumpRadialGolden(
      tester,
      boundaryKey: key,
      physicalSize: const Size(400, 400),
      wedges: _upgradeTownPresentWedges(),
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_upgrade_town.png'),
    );
  });

  testWidgets('golden: Upgrade town absent on non-town tile (AC-3)', (
    tester,
  ) async {
    final key = GlobalKey();
    await _pumpRadialGolden(
      tester,
      boundaryKey: key,
      physicalSize: const Size(400, 400),
      wedges: _upgradeTownAbsentWedges(),
    );
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_no_upgrade_town.png'),
    );
  });
}
