// MAP30001 Train {type} spoke relabel pins (Refs #4752).

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
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

  testWidgets('radial Train Explorer wedge shows the hire label', (
    tester,
  ) async {
    final kind = MapTrainCivilianKind.explorer;
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
  });

  testWidgets('More dialog Train Explorer row is enabled', (tester) async {
    TileRadialCatalogAction? tapped;
    final kind = MapTrainCivilianKind.explorer;
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
              caption: mapTrainCivilianGist(l10n, kind),
            ),
          ],
          onAction: (action) => tapped = action,
          onProvinceDetails: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Train Explorer'), findsOneWidget);
    await tester.tap(find.text('Train Explorer'));
    await tester.pump();
    expect(tapped, TileRadialCatalogAction.explore);
  });
}
