// Goldens for MAP30001 / MAP30002. SPEC/ui/tile-context-radial.md (Refs #4440).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
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
}

void _noop() {}

void _noopAction(TileRadialCatalogAction action) {}
