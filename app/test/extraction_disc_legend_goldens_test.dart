// Widget golden coverage for MAP10001 extraction-disc legend (#4367).
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/controls/extraction_disc_legend.dart';
import 'package:colonizethis_app/features/game/flame/controls/extraction_disc_legend_support.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

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
}
