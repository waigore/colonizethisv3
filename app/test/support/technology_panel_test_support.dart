// Shared TechnologyPanel widget-test scaffolding (Refs #4035).
// Canonical buildAppShell host + pump for technology_panel_* suites.
// SPEC: SPEC/ui/technology-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';

import 'app_shell_harness.dart';

/// Builds the canonical [TechnologyPanel] host used across the panel's widget
/// tests: editorial-monocle [buildAppShell] > [Scaffold] wrapping the panel.
///
/// When [wrapInScrollView] is true, the panel is wrapped in a
/// [SingleChildScrollView] (needed when researched-tech grids push slot
/// controls below the default test viewport). When [bodyWidth] is set, a
/// [SizedBox] constrains the body width before optional scrolling.
Widget buildTechnologyPanel({
  required Game game,
  required Player player,
  Orders currentOrders = const Orders(),
  void Function(Orders orders)? onOrdersChanged,
  bool wrapInScrollView = false,
  double? bodyWidth,
}) {
  Widget body = TechnologyPanel(
    game: game,
    player: player,
    currentOrders: currentOrders,
    onOrdersChanged: onOrdersChanged,
  );
  if (bodyWidth != null) {
    body = SizedBox(width: bodyWidth, child: body);
  }
  if (wrapInScrollView) {
    body = SingleChildScrollView(child: body);
  }
  return buildAppShell(child: Scaffold(body: body));
}

/// Pumps [buildTechnologyPanel] (or an optional prebuilt [widget]) and settles.
///
/// Canonical technology panel pump for panel suites — do not re-declare a local
/// `_pumpPanel` / `pumpPanel` clone (Refs #4035).
Future<void> pumpTechnologyPanel(
  WidgetTester tester, {
  required Game game,
  required Player player,
  Orders currentOrders = const Orders(),
  void Function(Orders orders)? onOrdersChanged,
  bool wrapInScrollView = false,
  double? bodyWidth,
  Widget? widget,
}) async {
  await tester.pumpWidget(
    widget ??
        buildTechnologyPanel(
          game: game,
          player: player,
          currentOrders: currentOrders,
          onOrdersChanged: onOrdersChanged,
          wrapInScrollView: wrapInScrollView,
          bodyWidth: bodyWidth,
        ),
  );
  await tester.pumpAndSettle();
}
