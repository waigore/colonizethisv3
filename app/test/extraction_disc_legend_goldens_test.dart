// Widget golden coverage for MAP10001 extraction-disc legend (#4367).
import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/controls/extraction_disc_legend.dart';
import 'package:colonizethis_app/features/game/flame/controls/extraction_disc_legend_support.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map_component_shared_palette.dart'
    show BaseLayerDisplayMode;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

Widget _legendCornerChrome({
  required BaseLayerDisplayMode mode,
  required String? viewingPlayerId,
}) {
  final GlobalKey anchor = GlobalKey();
  return ColoredBox(
    color: EditorialMonoclePalette.bgDeep,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shouldShowExtractionDiscLegend(
            baseLayerDisplayMode: mode,
            viewingPlayerId: viewingPlayerId,
          )) ...[
            ExtractionDiscLegend(
              key: anchor,
              narrow: false,
              anchorKey: anchor,
              chromeBottomY: 0,
            ),
            const SizedBox(height: 4),
          ],
          GameMapCornerControls(
            onCycleBaseLayerDisplayMode: () {},
            onCenterOnHomeCapital: () {},
            onOpenMapDisplayOptions: () {},
            homeToCapitalEnabled: viewingPlayerId != null,
          ),
        ],
      ),
    ),
  );
}

const List<String> _cornerIconAssets = <String>[
  '${kAppIconAssetPrefix}ui_icon_layer_toggle.png',
  '${kAppIconAssetPrefix}ui_icon_home_capital.png',
  '${kAppIconAssetPrefix}ui_icon_map_options.png',
];

Future<void> _pumpHiddenLegendGolden(
  WidgetTester tester, {
  required GlobalKey boundaryKey,
  required BaseLayerDisplayMode mode,
  required String? viewingPlayerId,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: const Size(160, 64),
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: _legendCornerChrome(mode: mode, viewingPlayerId: viewingPlayerId),
  );
  await pumpSettleCapped(tester);
  final BuildContext context = tester.element(
    find.byType(GameMapCornerControls),
  );
  await tester.runAsync(() async {
    for (final String asset in _cornerIconAssets) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pump();
  await pumpSettleCapped(tester);
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: extraction disc legend wide', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    final GlobalKey anchor = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(240, 72),
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      center: false,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ExtractionDiscLegend(
            key: anchor,
            narrow: false,
            anchorKey: anchor,
            chromeBottomY: 0,
          ),
        ),
      ),
    );
    await pumpSettleCapped(tester);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/extraction_disc_legend_wide.png'),
    );
  });

  testWidgets('golden: extraction disc legend narrow chip', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    final GlobalKey anchor = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(80, 40),
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      center: false,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ExtractionDiscLegend(
            key: anchor,
            narrow: true,
            anchorKey: anchor,
            chromeBottomY: 0,
          ),
        ),
      ),
    );
    await pumpSettleCapped(tester);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/extraction_disc_legend_narrow.png'),
    );
  });

  testWidgets('golden: extraction disc legend details panel', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(320, 260),
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      center: false,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Builder(
            builder: (BuildContext ctx) {
              return ExtractionDiscLegendPanel(
                l10n: appL10n(ctx),
                onClose: () {},
              );
            },
          ),
        ),
      ),
    );
    await pumpSettleCapped(tester);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/extraction_disc_legend_panel.png'),
    );
  });

  testWidgets('golden: extraction disc legend hidden in terrain only', (
    tester,
  ) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpHiddenLegendGolden(
      tester,
      boundaryKey: boundaryKey,
      mode: BaseLayerDisplayMode.terrainOnly,
      viewingPlayerId: 'gp_player',
    );
    expect(find.byKey(kExtractionDiscLegendKey), findsNothing);
    expect(find.byType(GameMapCornerControls), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/extraction_disc_legend_hidden_terrain_only.png',
      ),
    );
  });

  testWidgets('golden: extraction disc legend hidden in global observe', (
    tester,
  ) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpHiddenLegendGolden(
      tester,
      boundaryKey: boundaryKey,
      mode: BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
      viewingPlayerId: null,
    );
    expect(find.byKey(kExtractionDiscLegendKey), findsNothing);
    expect(find.byType(GameMapCornerControls), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/extraction_disc_legend_hidden_global_observe.png',
      ),
    );
  });
}
