// Golden host harness for unit panel captures (Refs #4734 Slice E, #3514).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_viewport_constraints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const kUnitPanelsGoldenHostViewport = Size(440, 820);

const kUnitPanelsGoldenPanelConstraints = BoxConstraints(
  maxWidth: 400,
  maxHeight: 760,
);

const kUnitPanelsGoldenMobileViewport = Size(360, 640);

final kUnitPanelsGoldenMobileConstraints = unitsPanelSheetConstraints(
  kUnitPanelsGoldenMobileViewport,
);

Widget unitPanelsGoldenHost({
  required Key boundaryKey,
  required Widget child,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    wrapInProviderScope: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: ConstrainedBox(
      constraints: kUnitPanelsGoldenPanelConstraints,
      child: child,
    ),
  );
}

Widget unitPanelsGoldenMobileHost({
  required Key boundaryKey,
  required Widget child,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    alignment: Alignment.bottomCenter,
    wrapInProviderScope: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: ConstrainedBox(
      constraints: kUnitPanelsGoldenMobileConstraints,
      child: child,
    ),
  );
}

Future<void> pumpUnitPanelsGoldenHost(
  WidgetTester tester,
  Widget panel,
  Key key,
) async {
  await configureGoldenSurface(tester, size: kUnitPanelsGoldenHostViewport);
  await tester.pumpWidget(unitPanelsGoldenHost(boundaryKey: key, child: panel));
  await pumpForGolden(tester);
}

Future<void> pumpUnitPanelsGoldenMobileHost(
  WidgetTester tester,
  Widget panel,
  Key key,
) async {
  await configureGoldenSurface(tester, size: kUnitPanelsGoldenMobileViewport);
  await tester.pumpWidget(
    unitPanelsGoldenMobileHost(boundaryKey: key, child: panel),
  );
  await pumpForGolden(tester);
}
