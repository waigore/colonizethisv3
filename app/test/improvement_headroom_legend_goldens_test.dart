// Widget golden coverage for MAP10001 improvement-headroom legend (#4408).
import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/flame/controls/improvement_headroom_legend.dart';
import 'package:colonizethis_app/features/game/flame/controls/improvement_headroom_legend_support.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

Widget _legendCornerChrome({
  required MapBaseLayerFlags flags,
  required String? viewingPlayerId,
  bool narrow = false,
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
          if (shouldShowImprovementHeadroomLegend(
            flags: flags,
            viewingPlayerId: viewingPlayerId,
          )) ...[
            ImprovementHeadroomLegend(
              key: anchor,
              narrow: narrow,
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
            mapBaseLayerFlags: flags,
            narrow: narrow,
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

Future<void> _pumpLegendGolden(
  WidgetTester tester, {
  required GlobalKey boundaryKey,
  required MapBaseLayerFlags flags,
  required String? viewingPlayerId,
  Size physicalSize = const Size(240, 96),
  bool narrow = false,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: _legendCornerChrome(
      flags: flags,
      viewingPlayerId: viewingPlayerId,
      narrow: narrow,
    ),
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

  testWidgets('golden: improvement headroom legend wide', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    final GlobalKey anchor = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(280, 96),
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      center: false,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ImprovementHeadroomLegend(
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
      matchesGoldenFile('goldens/improvement_headroom_legend_wide.png'),
    );
  });

  testWidgets('golden: improvement headroom legend details panel', (
    tester,
  ) async {
    final GlobalKey boundaryKey = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(320, 320),
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
              return ImprovementHeadroomLegendPanel(
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
      matchesGoldenFile('goldens/improvement_headroom_legend_panel.png'),
    );
  });

  testWidgets('golden: improvement headroom legend hidden when off', (
    tester,
  ) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpLegendGolden(
      tester,
      boundaryKey: boundaryKey,
      flags: MapBaseLayerFlags.resourcesOnly,
      viewingPlayerId: 'gp_player',
    );
    expect(find.byKey(kImprovementHeadroomLegendKey), findsNothing);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile(
        'goldens/improvement_headroom_legend_hidden_improvements_off.png',
      ),
    );
  });

  testWidgets('golden: improvement headroom legend at 320 dp', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpLegendGolden(
      tester,
      boundaryKey: boundaryKey,
      flags: MapBaseLayerFlags.fullDetail,
      viewingPlayerId: 'gp_player',
      physicalSize: const Size(320, 96),
      narrow: true,
    );
    expect(find.byKey(kImprovementHeadroomLegendKey), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/improvement_headroom_legend_320dp.png'),
    );
  });
}
