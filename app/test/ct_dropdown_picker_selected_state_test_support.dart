// Pump/finder helpers for CtDropdown picker selected-row tests (Refs #4734 Slice H).

import 'package:colonizethis_app/widgets/ct_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget ctDropdownPickerHost({
  required String? value,
  required ValueChanged<String?> onChanged,
  List<String> items = const ['England', 'France', 'Spain'],
}) {
  return buildAppShell(
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: 220,
          child: CtDropdown<String>(
            value: value,
            items: items,
            hint: 'Select nation',
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}

Future<void> openCtDropdownPicker(WidgetTester tester) async {
  final hitFinder = find.byKey(CtDropdown.kCtDropdownTriggerHitTargetKey);
  expect(hitFinder, findsOneWidget);
  await tester.tap(hitFinder);
  await tester.pumpAndSettle();
}

DecoratedBox ctDropdownSelectedRowBox(WidgetTester tester) {
  final finder = find.byKey(CtDropdown.kCtDropdownPickerSelectedRowKey);
  expect(finder, findsOneWidget);
  return tester.widget<DecoratedBox>(finder);
}

List<DecoratedBox> ctDropdownPickerRowOuterBoxes(WidgetTester tester) {
  final paddings = find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Padding),
  );
  final List<DecoratedBox> rowBoxes = <DecoratedBox>[];
  for (final element in paddings.evaluate()) {
    final padding = element.widget as Padding;
    final child = padding.child;
    if (child is DecoratedBox) {
      rowBoxes.add(child);
    }
  }
  return rowBoxes;
}
