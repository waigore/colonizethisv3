// Shared MaterialApp frames for combat_ui_specs_part*_test (Refs #4013).
// Pins SPEC/ui combat dialog and sub-view contracts under editorial monocle.

import 'package:flutter/material.dart';

import 'app_shell_harness.dart';

/// Light/default Material frame used for layout/content pins.
Widget combatUiSpecsFrame(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// Editorial-monocle dark frame used for palette/token pins.
Widget combatUiSpecsDarkFrame(Widget child) {
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  return buildAppShell(child: Scaffold(body: child));
}
