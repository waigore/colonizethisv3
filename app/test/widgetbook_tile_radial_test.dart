// Widgetbook mount pins for MAP30001 / MAP30002. Refs #4440.

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_context_radial.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_more_actions_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_keys.dart';
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

  group('Tile Context Radial Widgetbook', () {
    for (final useCaseName in [
      'Enabled three wedges',
      'Prospect enabled Explore disabled',
      'Empty catalog More-only',
      'Sea-zone few shortcuts',
      '320 dp clamp',
    ]) {
      testWidgets('$useCaseName mounts', (tester) async {
        final useCase = findWidgetbookUseCase(
          tileRadialDirectories,
          folderName: 'Tile Context Radial',
          useCaseName: useCaseName,
        );
        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: useCaseName == '320 dp clamp'
              ? const Size(320, 640)
              : const Size(400, 400),
        );
        expect(find.byType(TileContextRadial), findsOneWidget);
        expect(find.byKey(kTileRadialMoreKey), findsOneWidget);
      });
    }
  });

  group('More Tile Actions Widgetbook', () {
    for (final useCaseName in [
      'Empty remainder',
      'Remainder Prospect',
      '320 dp',
    ]) {
      testWidgets('$useCaseName mounts', (tester) async {
        final useCase = findWidgetbookUseCase(
          tileRadialDirectories,
          folderName: 'More Tile Actions',
          useCaseName: useCaseName,
        );
        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: useCaseName == '320 dp'
              ? const Size(320, 640)
              : const Size(400, 400),
        );
        expect(find.byType(TileMoreActionsDialog), findsOneWidget);
        expect(find.byKey(kTileMoreProvinceDetailsKey), findsOneWidget);
      });
    }
  });
}
