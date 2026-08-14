// Pump helpers for units-panel shared-widget tests (Refs #4352).

import 'package:colonizethis_app/features/game/widgets/units/shared/region_section_header.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Future<void> pumpUnitsSharedBody(WidgetTester tester, Widget body) async {
  await tester.pumpWidget(buildAppShell(child: Scaffold(body: body)));
}

Border unitsSharedHeaderBorder(WidgetTester tester, Type headerType) {
  final DecoratedBox decoratedBox = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(headerType),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (decoratedBox.decoration as BoxDecoration).border! as Border;
}

UnitsPanelShell emptyUnitsPanelShell({
  String title = 'Civilian Units',
  String emptyMessage = 'No civilian units',
  List<Widget> actions = const [],
}) {
  return UnitsPanelShell(
    title: title,
    actions: actions,
    hasContent: false,
    listChildren: const [],
    emptyMessage: emptyMessage,
  );
}

Future<void> pumpUnitsEntityActionRow(
  WidgetTester tester, {
  double width = 420,
  required List<UnitsEntityAction> actions,
}) async {
  await pumpUnitsSharedBody(
    tester,
    SizedBox(
      width: width,
      child: UnitsEntityActionRow(
        details: const Text('Left details'),
        actions: actions,
      ),
    ),
  );
}

UnitsEntityAction unitsEntityMoveAction({
  VoidCallback? onPressed,
  bool enabled = true,
}) {
  return UnitsEntityAction(
    tooltip: 'Move',
    icon: Icons.route,
    label: 'Move',
    onPressed: enabled ? (onPressed ?? () {}) : null,
  );
}

void expectRegionHeaderLeftBar(WidgetTester tester) {
  final Border border = unitsSharedHeaderBorder(tester, RegionSectionHeader);
  expect(border.left.width, RegionSectionHeader.leftBarWidth);
  expect(border.left.color, EditorialMonoclePalette.accentDim);
  expect(border.bottom, BorderSide.none);
}

void expectRegionHeaderBottomBorder(WidgetTester tester) {
  final Border border = unitsSharedHeaderBorder(tester, RegionSectionHeader);
  expect(border.bottom.width, RegionSectionHeader.bottomBorderWidth);
  expect(border.bottom.color, EditorialMonoclePalette.border);
  expect(border.left, BorderSide.none);
}
