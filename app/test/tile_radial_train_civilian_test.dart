// MAP30001 Train {type} spoke relabel pins (Refs #4752).

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_train_civilian.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_copy.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/map_train_civilian_offer.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsEn();

  setUpAll(preloadNinePatchImage);

  test('applyTileRadialTrainCivilianView relabels and sets the hire gist', () {
    final cases = <(TileRadialCatalogAction, MapTrainCivilianKind)>[
      (TileRadialCatalogAction.explore, MapTrainCivilianKind.explorer),
      (TileRadialCatalogAction.prospect, MapTrainCivilianKind.explorer),
      (TileRadialCatalogAction.buildImprovement, MapTrainCivilianKind.builder),
      (TileRadialCatalogAction.upgradeTown, MapTrainCivilianKind.builder),
      (TileRadialCatalogAction.buildRoad, MapTrainCivilianKind.engineer),
      (TileRadialCatalogAction.buildPort, MapTrainCivilianKind.engineer),
      (TileRadialCatalogAction.buildFort, MapTrainCivilianKind.engineer),
      (TileRadialCatalogAction.purchaseLand, MapTrainCivilianKind.merchant),
      (TileRadialCatalogAction.buildRail, MapTrainCivilianKind.railBuilder),
    ];
    for (final (action, kind) in cases) {
      final view = applyTileRadialTrainCivilianView(
        view: TileRadialSpokeView(
          action: action,
          enabled: false,
          label: 'Work',
          tooltip: 'Work',
        ),
        l10n: l10n,
        offerTrain: true,
      );
      expect(view.enabled, isTrue);
      expect(view.label, mapTrainCivilianLabel(l10n, kind));
      expect(view.caption, mapTrainCivilianGist(l10n, kind));
    }
    expect(
      cases.map((c) => c.$1).toSet(),
      TileRadialCatalogAction.values.toSet(),
    );
  });

  testWidgets('radial Train Explorer wedge shows the hire label and gist', (
    tester,
  ) async {
    final kind = MapTrainCivilianKind.explorer;
    final gist = mapTrainCivilianGist(l10n, kind);
    await tester.pumpWidget(
      buildAppShell(
        viewport: const Size(800, 800),
        child: TileContextRadial(
          placeLine: 'Test province',
          wedges: [
            TileRadialSpokeView(
              action: TileRadialCatalogAction.explore,
              enabled: true,
              label: mapTrainCivilianLabel(l10n, kind),
              tooltip: mapTrainCivilianLabel(l10n, kind),
              caption: gist,
            ),
          ],
          onWedge: (_) {},
          onMore: () {},
          onDismiss: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Train Explorer'), findsOneWidget);
    expect(find.text(gist), findsWidgets);
  });

  testWidgets('More dialog Train Explorer row is enabled with gist', (
    tester,
  ) async {
    TileRadialCatalogAction? tapped;
    final kind = MapTrainCivilianKind.explorer;
    final gist = mapTrainCivilianGist(l10n, kind);
    await tester.pumpWidget(
      buildAppShell(
        child: TileMoreActionsDialog(
          placeLine: 'Test province',
          remainder: [
            TileRadialSpokeView(
              action: TileRadialCatalogAction.explore,
              enabled: true,
              label: mapTrainCivilianLabel(l10n, kind),
              tooltip: mapTrainCivilianLabel(l10n, kind),
              caption: gist,
            ),
          ],
          onAction: (action) => tapped = action,
          onProvinceDetails: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Train Explorer'), findsOneWidget);
    expect(find.text(gist), findsOneWidget);
    await tester.tap(find.text('Train Explorer'));
    await tester.pump();
    expect(tapped, TileRadialCatalogAction.explore);
  });
}
