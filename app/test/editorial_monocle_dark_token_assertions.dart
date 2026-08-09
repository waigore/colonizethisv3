// Shared editorial-monocle dark-token / chrome assertion helpers. Refs #4013 / #4021.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// ARGB int identity for [Color] equality across flutter_test / golden hosts.
int editorialMonocleArgb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

/// Asserts [color] is explicit [EditorialMonoclePalette.muted] (not white,
/// not [onSurface], not null DefaultTextStyle fall-through).
void expectMutedSingleSource(Color? color, Color onSurface, String label) {
  expect(
    color,
    isNotNull,
    reason: 'Material defaults: $label must declare TextStyle.color.',
  );
  expect(
    color,
    isNot(equals(Colors.white)),
    reason: 'Material defaults: $label must not be Colors.white.',
  );
  expect(
    color,
    isNot(equals(onSurface)),
    reason:
        'Material defaults: $label must not use colorScheme.onSurface; '
        'use EditorialMonoclePalette.muted.',
  );
  expect(
    color,
    equals(EditorialMonoclePalette.muted),
    reason: '$label must resolve to EditorialMonoclePalette.muted.',
  );
}

/// Asserts [color] is explicit [EditorialMonoclePalette.fg] (not white, not
/// null). Omits `isNot(onSurface)` because editorialMonocle wires onSurface to
/// fg.
void expectFgSingleSource(Color? color, String label) {
  expect(
    color,
    isNotNull,
    reason: 'Material defaults: $label must declare TextStyle.color.',
  );
  expect(
    color,
    isNot(equals(Colors.white)),
    reason: 'Material defaults: $label must not be Colors.white.',
  );
  expect(
    color,
    equals(EditorialMonoclePalette.fg),
    reason: '$label must resolve to EditorialMonoclePalette.fg.',
  );
}

/// Asserts an obfuscated `???` [Text] body row uses muted with an explicit
/// style color.
void expectMutedObfuscated(Text widget, {required String context}) {
  final data = widget.data ?? '';
  expect(
    widget.style?.color,
    isNotNull,
    reason: 'Obfuscated "$data" ($context) must declare TextStyle.color.',
  );
  expect(
    widget.style?.color,
    isNot(equals(Colors.white)),
    reason: 'Obfuscated "$data" ($context) must not be Colors.white.',
  );
  expect(
    widget.style?.color,
    equals(EditorialMonoclePalette.muted),
    reason:
        'Obfuscated "$data" ($context) must resolve to '
        'EditorialMonoclePalette.muted.',
  );
}

/// Asserts the pumped tree is under editorial-monocle dark chrome.
void expectEditorialMonocleDarkChrome(
  WidgetTester tester, {
  String reason =
      'Surfaces must render under the editorial-monocle dark theme',
}) {
  final BuildContext ctx = tester.element(find.byType(Scaffold).first);
  final ThemeData theme = Theme.of(ctx);
  expect(theme.brightness, Brightness.dark);
  expect(
    editorialMonocleArgb(theme.colorScheme.primary),
    editorialMonocleArgb(EditorialMonoclePalette.accent),
    reason: reason,
  );
}
