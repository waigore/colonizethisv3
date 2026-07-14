// Shared editorial-monocle dark-token / chrome assertion helpers for app widget
// tests. Refs #4013.

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

/// Asserts [color] is an explicit [EditorialMonoclePalette.muted] (not white,
/// not [onSurface], not null DefaultTextStyle fall-through).
void expectMutedSingleSource(Color? color, Color onSurface, String label) {
  expect(
    color,
    isNotNull,
    reason:
        'Material defaults regression guard: the $label placeholder '
        'must declare its own TextStyle.color rather than relying on '
        'DefaultTextStyle fall-through.',
  );
  expect(
    color,
    isNot(equals(Colors.white)),
    reason:
        'Material defaults regression guard: the $label placeholder '
        'must not resolve to the dark Material `Colors.white` fallback.',
  );
  expect(
    color,
    isNot(equals(onSurface)),
    reason:
        'Material defaults regression guard: the $label placeholder '
        'must not resolve to Theme.of(context).colorScheme.onSurface (the '
        'dark Material `bodyMedium` proxy — distinct from '
        '`EditorialMonoclePalette.muted` under any non-`editorialMonocle` '
        'theme).',
  );
  expect(
    color,
    equals(EditorialMonoclePalette.muted),
    reason:
        'Material defaults regression guard: the $label placeholder '
        'must resolve to EditorialMonoclePalette.muted (the single source).',
  );
}

/// Asserts an obfuscated `???` [Text] body row uses
/// [EditorialMonoclePalette.muted] with an explicit style color.
void expectMutedObfuscated(Text widget, {required String context}) {
  expect(
    widget.style?.color,
    isNotNull,
    reason:
        'Material defaults regression guard: obfuscated body row '
        '"${widget.data}" ($context) must declare its own '
        'TextStyle.color rather than relying on DefaultTextStyle '
        'fall-through.',
  );
  expect(
    widget.style?.color,
    isNot(equals(Colors.white)),
    reason:
        'Material defaults regression guard: obfuscated body row '
        '"${widget.data}" ($context) must not resolve to the dark '
        'Material `Colors.white` fallback.',
  );
  expect(
    widget.style?.color,
    equals(EditorialMonoclePalette.muted),
    reason:
        'Obfuscated body row "${widget.data}" ($context) must resolve '
        'TextStyle.color to EditorialMonoclePalette.muted per SPEC '
        '§ Dark-theme obfuscated `???` body tokens.',
  );
}

/// Asserts the pumped tree is under editorial-monocle dark chrome
/// (`Brightness.dark` + accent primary).
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
