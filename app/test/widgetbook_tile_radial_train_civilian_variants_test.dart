// Widgetbook pins for MAP30001 / MAP30002 Train {type} (Refs #4752).

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widget_test_assets.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(preloadNinePatchImage);
  final l10n = AppLocalizationsEn();
  const useCaseName = 'Train Explorer missing-unit';

  testWidgets('radial Train Explorer missing-unit is catalogued', (
    tester,
  ) async {
    final useCase = findWidgetbookUseCase(
      tileRadialDirectories,
      folderName: 'Tile Context Radial',
      useCaseName: useCaseName,
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      useCase,
      size: const Size(400, 400),
    );
    expect(find.byType(TileContextRadial), findsOneWidget);
    expect(find.text('Train Explorer'), findsOneWidget);
    expect(
      find.text(l10n.provinceOverlay_trainCivilianGistExplorer),
      findsWidgets,
    );
  });

  testWidgets('More Train Explorer missing-unit is catalogued', (tester) async {
    final useCase = findWidgetbookUseCase(
      tileRadialDirectories,
      folderName: 'More Tile Actions',
      useCaseName: useCaseName,
    );
    await pumpWidgetbookUseCaseAtSize(
      tester,
      useCase,
      size: const Size(400, 400),
    );
    expect(find.byType(TileMoreActionsDialog), findsOneWidget);
    expect(find.text('Train Explorer'), findsOneWidget);
    expect(
      find.text(l10n.provinceOverlay_trainCivilianGistExplorer),
      findsOneWidget,
    );
  });
}
