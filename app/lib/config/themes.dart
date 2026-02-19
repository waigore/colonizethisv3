import 'package:flutter/material.dart';

/// App themes. Phase 6: pixel-art canon and styling per UXD apply to existing UIs (03a–03m).
/// Asset pipeline: assets/images/; load in Flame/Flutter via rootBundle or Flame cache.
class AppThemes {
  AppThemes._();

  static ThemeData get light => ThemeData.light(useMaterial3: true);
}
