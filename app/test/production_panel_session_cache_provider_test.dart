// Session-cache reuse for Production panel providers (Refs #4688 Slice 2).

import 'package:colonizethis_app/providers/production_panel_projection_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'development_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'production_cache');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  test(
    'productionPanelOpenPathProvider reuses session cache after autoDispose teardown (Refs #4688 Slice 2)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final listener = container.listen(
        productionPanelOpenPathProvider,
        (_, __) {},
      );
      final openPathFirst = container.read(productionPanelOpenPathProvider);
      expect(openPathFirst, isNotNull);

      listener.close();
      final openPathSecond = container.read(productionPanelOpenPathProvider);
      expect(identical(openPathFirst, openPathSecond), isTrue);
    },
  );

  test(
    'productionPanelIndustryCounselProvider reuses session cache after autoDispose teardown (Refs #4688 Slice 2)',
    () {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: developmentPanelProjectionProviderOverrides(game),
      );
      addTearDown(container.dispose);

      final listener = container.listen(
        productionPanelIndustryCounselProvider,
        (_, __) {},
      );
      final counselFirst = container.read(
        productionPanelIndustryCounselProvider,
      );
      expect(counselFirst, isNotNull);

      listener.close();
      final counselSecond = container.read(
        productionPanelIndustryCounselProvider,
      );
      expect(identical(counselFirst, counselSecond), isTrue);
    },
  );
}
