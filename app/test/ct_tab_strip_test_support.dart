// Pump/decoration helpers for CtTabStrip widget tests (Refs #4305).

import 'package:colonizethis_app/widgets/ct_tab_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget ctTabStripTestHost(Widget child, {ThemeData? themeOverride}) {
  final Widget body = themeOverride == null
      ? child
      : Theme(data: themeOverride, child: child);
  return buildAppShell(child: Scaffold(body: body));
}

Container ctTabStripContainerForLabel(WidgetTester tester, String label) {
  final Finder labelFinder = find.text(label);
  final Element labelElement = tester.element(labelFinder);
  Container? container;
  labelElement.visitAncestorElements((Element ancestor) {
    final Widget widget = ancestor.widget;
    if (widget is Container) {
      container = widget;
      return false;
    }
    return true;
  });
  if (container == null) {
    throw StateError('No Container ancestor for tab label "$label"');
  }
  return container!;
}

BoxDecoration ctTabStripDecoration(WidgetTester tester, String label) {
  final Container container = ctTabStripContainerForLabel(tester, label);
  final Decoration? decoration = container.decoration;
  if (decoration is! BoxDecoration) {
    throw StateError(
      'Tab container for "$label" decoration is not BoxDecoration (got '
      '${decoration.runtimeType})',
    );
  }
  return decoration;
}

Widget ctTabStripPaletteHarness({
  required List<String> labels,
  ThemeData? themeOverride,
}) {
  final List<Widget> views = labels
      .map((String l) => Text('Body $l', key: ValueKey<String>('body-$l')))
      .toList(growable: false);
  return ctTabStripTestHost(
    SizedBox(
      height: 200,
      child: CtTabStrip(tabLabels: labels, tabViews: views),
    ),
    themeOverride: themeOverride,
  );
}
