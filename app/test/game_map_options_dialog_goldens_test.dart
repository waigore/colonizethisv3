// Widget goldens for MAP10001 Map display options (#4388).
// SPEC/ui/empire-overview.md § Map display options / Widgetbook.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/dialogs/game_map_options_dialog.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';

const Size _dialogHost = Size(420, 580);

Future<void> _pumpOptionsGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required MapViewState initialState,
  Size physicalSize = _dialogHost,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: GameMapOptionsDialog(initialState: initialState, onChanged: (_) {}),
  );
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: map options all-on defaults with renamed borders row '
      '(Refs #4388)', (WidgetTester tester) async {
    const boundaryKey = ValueKey<String>('game_map_options_all_on_golden');
    await _pumpOptionsGolden(
      tester,
      boundaryKey: boundaryKey,
      initialState: MapViewState.defaults,
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text('Show province and sea borders'), findsOneWidget);
    expect(find.text('Map marks'), findsOneWidget);
    expect(find.byType(CtToggleSwitch), findsNWidgets(7));

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/game_map_options_dialog_all_on.png'),
    );
  });

  testWidgets('golden: map options terrain-only (Refs #4388)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'game_map_options_terrain_only_golden',
    );
    await _pumpOptionsGolden(
      tester,
      boundaryKey: boundaryKey,
      initialState: const MapViewState(
        showProvinceOverlay: false,
        showProvinceOwnershipTint: false,
        showProvinceNamesLayer: false,
        showMapResources: false,
        showMapImprovements: false,
        showMapRoads: false,
      ),
    );

    expect(tester.takeException(), isNull);
    final resources = tester.widget<CtToggleSwitch>(
      find.byKey(kGameMapOptionsShowMapResourcesToggleKey),
    );
    expect(resources.value, isFalse);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/game_map_options_dialog_terrain_only.png'),
    );
  });

  testWidgets('golden: map options resources-only (Refs #4388)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'game_map_options_resources_only_golden',
    );
    await _pumpOptionsGolden(
      tester,
      boundaryKey: boundaryKey,
      initialState: const MapViewState(
        showMapResources: true,
        showMapImprovements: false,
        showMapRoads: false,
      ),
    );

    expect(tester.takeException(), isNull);
    final resources = tester.widget<CtToggleSwitch>(
      find.byKey(kGameMapOptionsShowMapResourcesToggleKey),
    );
    final improvements = tester.widget<CtToggleSwitch>(
      find.byKey(kGameMapOptionsShowMapImprovementsToggleKey),
    );
    final roads = tester.widget<CtToggleSwitch>(
      find.byKey(kGameMapOptionsShowMapRoadsToggleKey),
    );
    expect(resources.value, isTrue);
    expect(improvements.value, isFalse);
    expect(roads.value, isFalse);
    expect(roads.onChanged, isNull);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/game_map_options_dialog_resources_only.png'),
    );
  });

  testWidgets(
    'golden: map options improvements without resources (Refs #4388)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'game_map_options_improvements_without_resources_golden',
      );
      await _pumpOptionsGolden(
        tester,
        boundaryKey: boundaryKey,
        initialState: const MapViewState(
          showMapResources: false,
          showMapImprovements: true,
          showMapRoads: false,
        ),
      );

      expect(tester.takeException(), isNull);
      final resources = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowMapResourcesToggleKey),
      );
      final improvements = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowMapImprovementsToggleKey),
      );
      expect(resources.value, isFalse);
      expect(improvements.value, isTrue);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/game_map_options_dialog_improvements_without_resources.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: map options roads disabled when improvements off (Refs #4388)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'game_map_options_roads_disabled_golden',
      );
      await _pumpOptionsGolden(
        tester,
        boundaryKey: boundaryKey,
        initialState: const MapViewState(
          showMapImprovements: false,
          showMapRoads: false,
        ),
      );

      expect(tester.takeException(), isNull);
      final roads = tester.widget<CtToggleSwitch>(
        find.byKey(kGameMapOptionsShowMapRoadsToggleKey),
      );
      expect(roads.value, isFalse);
      expect(roads.onChanged, isNull);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/game_map_options_dialog_roads_disabled.png'),
      );
    },
  );

  testWidgets('golden: map options defaults at 320 dp (Refs #4388)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('game_map_options_320dp_golden');
    await _pumpOptionsGolden(
      tester,
      boundaryKey: boundaryKey,
      initialState: MapViewState.defaults,
      physicalSize: const Size(kMinViewportWidth, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Show province and sea borders'), findsOneWidget);
    expect(find.byType(CtToggleSwitch), findsNWidgets(7));

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/game_map_options_dialog_320dp.png'),
    );
  });
}
