// Shared combat_ui_specs_part* frames (Refs #4013, #4035).

import 'package:flutter/material.dart';

import 'app_shell_harness.dart';

/// Light Material frame for layout/content pins.
Widget combatUiSpecsFrame(Widget child) => buildAppShell(
      theme: ThemeData.light(),
      child: Scaffold(body: child),
    );

/// Editorial-monocle dark frame for palette/token pins.
Widget combatUiSpecsDarkFrame(Widget child) =>
    buildAppShell(child: Scaffold(body: child));
