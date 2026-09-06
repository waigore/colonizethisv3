// Pump harness for cargo hold indicator goldens (#4253, #4734 Slice J).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/shell/cargo_hold_indicator_support.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar.dart';
import 'package:colonizethis_app/features/game/widgets/shell/game_tab_bar_indicators.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

const Size kCargoHoldIndicatorViewport = Size(160, 48);

TextStyle cargoHoldGoldenMonoLabelStyle(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
    fontFamily: 'monospace',
    fontSize: 11,
    height: 1.0,
  );
}

Future<void> pumpCargoHoldIndicatorGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required int used,
  required int capacity,
  required String label,
}) async {
  final Color numericColor = cargoHoldNumericColor(
    used: used,
    capacity: capacity,
    cargoNotDefined: false,
    isCargoUsedReliable: true,
  );
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: kCargoHoldIndicatorViewport,
    includeLocalizations: true,
    scaffoldBackgroundColor:
        AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.surface,
        border: Border(
          bottom: BorderSide(color: EditorialMonoclePalette.border),
        ),
      ),
      child: SizedBox(
        height: GameTabBar.height,
        child: Builder(
          builder: (BuildContext context) {
            return GameTabBarCargoHoldIndicator(
              cargoHoldLabel: label,
              labelStyle: cargoHoldGoldenMonoLabelStyle(context),
              numericColor: numericColor,
            );
          },
        ),
      ),
    ),
  );
  await pumpSettleCapped(tester);
}
