// Pixel goldens for MAP30001 / MAP30002 Train {type} (Refs #4752).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

const _gist =
    'A new Explorer appears at your capital after Next turn. This does not assign Explore or Prospect on this tile.';

TileRadialSpokeView _trainExplorerSpoke() {
  return const TileRadialSpokeView(
    action: TileRadialCatalogAction.explore,
    enabled: true,
    label: 'Train Explorer',
    tooltip: 'Train Explorer',
    caption: _gist,
  );
}

void main() {
  suppressLogsForTests();
  final l10n = AppLocalizationsEn();

  testWidgets('golden: MAP30001 Train Explorer missing-unit', (tester) async {
    expect(l10n.provinceOverlay_trainCivilianGistExplorer, _gist);
    final key = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: key,
      physicalSize: const Size(400, 400),
      includeLocalizations: true,
      center: false,
      scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: TileContextRadial(
          placeLine: 'Place: Wessex',
          wedges: [_trainExplorerSpoke()],
          onWedge: (_) {},
          onMore: () {},
          onDismiss: () {},
          anchor: const Offset(200, 200),
        ),
      ),
    );
    await pumpSettleCapped(tester);
    expect(find.text('Train Explorer'), findsOneWidget);
    expect(find.text(_gist), findsWidgets);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_train_explorer.png'),
    );
  });

  testWidgets('golden: MAP30001 Train Explorer 320 dp wrap', (tester) async {
    final key = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: key,
      physicalSize: const Size(320, 640),
      includeLocalizations: true,
      center: false,
      scaffoldBackgroundColor: EditorialMonoclePalette.bgDeep,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: TileContextRadial(
          placeLine: 'Place: Wessex',
          wedges: [_trainExplorerSpoke()],
          onWedge: (_) {},
          onMore: () {},
          onDismiss: () {},
          anchor: const Offset(16, 16),
        ),
      ),
    );
    await pumpSettleCapped(tester);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_context_radial_train_explorer_320.png'),
    );
  });

  testWidgets('golden: MAP30002 Train Explorer missing-unit', (tester) async {
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
        remainder: [_trainExplorerSpoke()],
        onAction: (_) {},
        onProvinceDetails: () {},
      ),
    );
    await pumpSettleCapped(tester);
    expect(find.text('Train Explorer'), findsOneWidget);
    expect(find.text(_gist), findsOneWidget);
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('goldens/tile_more_actions_train_explorer.png'),
    );
  });
}
