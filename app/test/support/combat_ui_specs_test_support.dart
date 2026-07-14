// Shared MaterialApp frames for combat_ui_specs_part*_test (Refs #4013).
// Pins SPEC/ui combat dialog and sub-view contracts under editorial monocle.

import 'package:colonizethis_app/config/themes.dart';
import 'package:flutter/material.dart';

/// Light/default Material frame used for layout/content pins.
Widget combatUiSpecsFrame(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// Editorial-monocle dark frame used for palette/token pins.
Widget combatUiSpecsDarkFrame(Widget child) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(body: child),
  );
}
