// Presentational MAP30002 More dialog. SPEC/ui/tile-more-actions-dialog.md.

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_keys.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_spoke_view.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Future<void> _pumpDialog(
  WidgetTester tester, {
  List<TileRadialSpokeView> remainder = const [],
  VoidCallback? onProvinceDetails,
  ValueChanged<TileRadialCatalogAction>? onAction,
  Size viewport = const Size(400, 640),
}) {
  return pumpAppShell(
    tester,
    viewport: viewport,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    child: TileMoreActionsDialog(
      placeLine: 'Place: Wessex',
      remainder: remainder,
      onAction: onAction ?? (_) {},
      onProvinceDetails: onProvinceDetails ?? () {},
    ),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('lists Province details first and omits excluded actions', (
    tester,
  ) async {
    await _pumpDialog(
      tester,
      remainder: const [
        TileRadialSpokeView(
          action: TileRadialCatalogAction.prospect,
          enabled: true,
          label: 'Prospect',
          tooltip: 'Prospect with explorer',
        ),
      ],
    );
    expect(find.byKey(kTileMoreActionsDialogKey), findsOneWidget);
    expect(find.byKey(kTileMoreProvinceDetailsKey), findsOneWidget);
    expect(find.text('Province details'), findsOneWidget);
    expect(find.text('Prospect'), findsOneWidget);
    expect(find.text('Explore'), findsNothing);
    expect(find.text('Spy station'), findsNothing);
    expect(find.text('Station spy'), findsNothing);
    expect(find.text('Blockade'), findsNothing);
    expect(find.text('Beachhead'), findsNothing);
    expect(find.text('Invade'), findsNothing);
    expect(find.text('Establish Consulate'), findsNothing);
    expect(find.text('Offer Peace'), findsNothing);
    expect(find.text('Counter-espionage'), findsNothing);
  });

  testWidgets('remainder can list Build road overflow from the catalog', (
    tester,
  ) async {
    await _pumpDialog(
      tester,
      remainder: const [
        TileRadialSpokeView(
          action: TileRadialCatalogAction.buildRoad,
          enabled: true,
          label: 'Build road',
          tooltip: 'Build road',
        ),
      ],
    );
    expect(find.text('Build road'), findsOneWidget);
    expect(find.byKey(kTileRadialBuildRoadKey), findsOneWidget);
  });

  testWidgets('Province details row fires the host callback', (tester) async {
    var details = false;
    await _pumpDialog(tester, onProvinceDetails: () => details = true);
    await tester.tap(find.byKey(kTileMoreProvinceDetailsKey));
    await tester.pump();
    expect(details, isTrue);
  });

  testWidgets('enabled remainder Explore row reports the catalog action', (
    tester,
  ) async {
    TileRadialCatalogAction? committed;
    await _pumpDialog(
      tester,
      viewport: const Size(400, 900),
      remainder: const [
        TileRadialSpokeView(
          action: TileRadialCatalogAction.explore,
          enabled: true,
          label: 'Explore',
          tooltip: 'Explore with explorer',
        ),
      ],
      onAction: (action) => committed = action,
    );
    await tester.tap(find.byKey(kTileRadialExploreKey));
    await tester.pump();
    expect(committed, TileRadialCatalogAction.explore);
  });

  testWidgets('320 dp dialog does not overflow horizontally', (tester) async {
    await _pumpDialog(
      tester,
      viewport: const Size(320, 640),
      remainder: const [
        TileRadialSpokeView(
          action: TileRadialCatalogAction.explore,
          enabled: true,
          label: 'Explore',
          tooltip: 'Explore with explorer',
        ),
        TileRadialSpokeView(
          action: TileRadialCatalogAction.prospect,
          enabled: true,
          label: 'Prospect',
          tooltip: 'Prospect with explorer',
        ),
        TileRadialSpokeView(
          action: TileRadialCatalogAction.buildImprovement,
          enabled: true,
          label: 'Build improvement',
          tooltip: 'Build improvement',
        ),
      ],
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(kTileMoreActionsDialogKey), findsOneWidget);
  });
}
