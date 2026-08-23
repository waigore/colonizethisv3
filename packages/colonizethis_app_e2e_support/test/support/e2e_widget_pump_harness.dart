// Shared MaterialApp / Scaffold pump hosts for colonizethis_app_e2e_support
// widget-test pins (#4598 Slice B). Pin suites import these instead of
// re-declaring `_wrap` / `_pumpScaffold` / `_pumpEmpty` clones.
//
// Dialog-launcher (`showDialog`) hosts live in
// `e2e_alert_dialog_pump_harness.dart`. Next-turn confirm hosts live in
// `next_turn_advance_harness.dart` (extends `next_turn_label_harness.dart`
// by adding the `common_yes` chip). Existing `any_explorer_assign_fleet_harness`
// and `expect_panel_texts_harness` wrap helpers delegate here.
//
// Do not change production helper semantics from here — test scaffolding only.
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bare [MaterialApp] + [Scaffold] shell used by region-chip, fleet-loop,
/// and other pins that only need a hittable body.
Widget wrapE2eScaffold(
  Widget body, {
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale>? supportedLocales,
}) {
  return MaterialApp(
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales ?? const <Locale>[Locale('en')],
    home: Scaffold(body: body),
  );
}

Future<void> pumpE2eScaffold(
  WidgetTester tester,
  Widget body, {
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale>? supportedLocales,
}) {
  return tester.pumpWidget(
    wrapE2eScaffold(
      body,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
    ),
  );
}

/// Empty scaffold used when the helper under test only reads finders /
/// snapshots and does not care about body widgets.
Future<void> pumpE2eEmptyScaffold(WidgetTester tester) {
  return tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
}

/// Empty [MaterialApp] (no [Scaffold]) used by pump-until timeout pins.
Future<void> pumpE2eEmptyApp(WidgetTester tester) {
  return tester.pumpWidget(const MaterialApp(home: SizedBox()));
}

/// Panel-root [KeyedSubtree] + [ListView] inside the shared scaffold, matching
/// [expect_panel_texts_harness] / civilian-panel opener preconditions.
Widget wrapE2eKeyedPanel({
  required Key panelRootKey,
  required List<Widget> children,
}) {
  return wrapE2eScaffold(
    KeyedSubtree(
      key: panelRootKey,
      child: ListView(children: children),
    ),
  );
}

Future<void> pumpE2eKeyedPanel(
  WidgetTester tester, {
  required Key panelRootKey,
  required List<Widget> children,
}) {
  return tester.pumpWidget(
    wrapE2eKeyedPanel(panelRootKey: panelRootKey, children: children),
  );
}

/// [MaterialApp] with app l10n delegates (next-turn / confirm chips).
Widget wrapE2eLocalizedScaffold(Widget body) {
  return wrapE2eScaffold(
    body,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

Future<void> pumpE2eLocalizedScaffold(WidgetTester tester, Widget body) {
  return tester.pumpWidget(wrapE2eLocalizedScaffold(body));
}
