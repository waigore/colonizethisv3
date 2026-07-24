// Shared combat_ui_specs_part* frames (Refs #4013, #4035 / #4117 slice F).

import 'package:flutter/material.dart';

import 'app_shell_harness.dart';

/// Material frame for layout/content pins ([theme] defaults to light).
Widget combatUiSpecsFrame(
  Widget child, {
  ThemeData? theme,
}) =>
    buildAppShell(
      theme: theme ?? ThemeData.light(),
      child: Scaffold(body: child),
    );

/// Editorial-monocle dark frame for palette/token pins.
Widget combatUiSpecsDarkFrame(Widget child) => buildPanelScaffoldShell(child);
