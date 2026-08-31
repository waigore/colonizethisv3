// Pump/assert helpers for dialogue_overlays_specs_view_and_intro_test.dart (Refs #4680).

import 'dart:io' show File;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogue_overlays_specs_test_support.dart';

Iterable<Material> gameStartIntroScrimMaterials(WidgetTester tester) {
  return tester
      .widgetList<Material>(
        find.descendant(
          of: find.byType(GameStartIntroOverlay),
          matching: find.byType(Material),
        ),
      )
      .where((m) => m.color == EditorialMonoclePalette.dialogScrim);
}

Future<void> expectGameStartIntroScrimUsesDialogToken(
  WidgetTester tester, {
  required AssetBundle lineBundle,
  required AssetBundle errorBundle,
}) async {
  await tester.pumpWidget(
    wrapGameStartIntroOverlay(
      bundle: lineBundle,
      onDismissed: () {},
    ),
  );
  await pumpDialogueOverlaysUntilSettled(tester);

  expect(
    gameStartIntroScrimMaterials(tester),
    isNotEmpty,
    reason:
        'presenting-line scrim must paint '
        'EditorialMonoclePalette.dialogScrim, not a hex literal.',
  );
  expect(
    tester
        .widgetList<Material>(find.byType(Material))
        .any((m) => m.color == Colors.black54),
    isFalse,
    reason: 'No Material may paint the legacy Colors.black54 scrim.',
  );

  await tester.pumpWidget(
    wrapGameStartIntroOverlay(
      bundle: errorBundle,
      onDismissed: () {},
    ),
  );
  await pumpDialogueOverlaysUntilSettled(tester);

  expect(
    gameStartIntroScrimMaterials(tester),
    isNotEmpty,
    reason:
        'error scrim must also paint '
        'EditorialMonoclePalette.dialogScrim, not a hex literal.',
  );
}

void expectGameStartIntroSourceContract() {
  final source = dialogueOverlaysLibraryUnitSource(
    'lib/features/game/widgets/dialogue/game_start_intro_overlay.dart',
  );
  expect(
    source.contains('Colors.black54'),
    isFalse,
    reason:
        'Refs #2867 S10: intro overlay scrim must resolve from the '
        'EditorialMonoclePalette.dialogScrim token; Colors.black54 was '
        'the legacy hex-literal scrim and must not return.',
  );
  expect(
    source.contains('EditorialMonoclePalette.dialogScrim') ||
        source.contains('CtFullScreenDialogueShell') ||
        source.contains('buildTitledDialogueChrome'),
    isTrue,
    reason:
        'Refs #2867 S10 / #2914 S2 / #4018: intro overlay scrim must resolve '
        'to the canonical EditorialMonoclePalette.dialogScrim token, either '
        'directly, via CtFullScreenDialogueShell, or via '
        'buildTitledDialogueChrome (which wraps that shell).',
  );
  final shellSource = File(
    'lib/widgets/ct_full_screen_dialogue_shell.dart',
  ).readAsStringSync();
  expect(
    shellSource.contains('EditorialMonoclePalette.dialogScrim'),
    isTrue,
    reason:
        'Refs #2914 S2: CtFullScreenDialogueShell is the canonical scrim '
        'host for dialogue overlays and must paint '
        'EditorialMonoclePalette.dialogScrim.',
  );
}
