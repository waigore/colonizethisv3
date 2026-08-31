// Variant pump/assert helpers for ct_nine_patch_button_dark_test.dart (Refs #4680).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_nine_patch_button_dark_test_support.dart';

Future<void> expectNinePatchDangerVariant(WidgetTester tester) async {
  await pumpNinePatchButton(
    tester,
    onPressed: () {},
    dangerVariant: true,
    child: const Text('Declare War'),
  );
  expectNinePatchGradientColors(tester, CtGradients.buttonGradient.colors);
  expectNinePatchBorderColor(tester, EditorialMonoclePalette.danger);
  expectNinePatchLabelColor(
    tester,
    'Declare War',
    EditorialMonoclePalette.danger,
  );
}

Future<void> expectNinePatchMutedIdleVariant(WidgetTester tester) async {
  await pumpNinePatchButton(
    tester,
    onPressed: () {},
    mutedVariant: true,
    child: const Text('Do naught'),
  );
  expectNinePatchBorderColor(tester, EditorialMonoclePalette.accentDim);
  expect(
    (ninePatchButtonSurfaceDecoration(tester).border! as Border).top.color,
    isNot(EditorialMonoclePalette.border),
  );
  expectNinePatchLabelColor(
    tester,
    'Do naught',
    EditorialMonoclePalette.muted,
  );
  expectNinePatchGradientColors(tester, CtGradients.buttonGradient.colors);
}

Future<void> expectNinePatchMutedHoverVariant(WidgetTester tester) async {
  await pumpNinePatchButton(
    tester,
    onPressed: () {},
    mutedVariant: true,
    child: const Text('Diplomatic protest'),
  );
  await hoverOverNinePatchButton(tester);
  expectNinePatchBorderColor(tester, EditorialMonoclePalette.accent);
  expectNinePatchLabelColor(
    tester,
    'Diplomatic protest',
    EditorialMonoclePalette.accent,
  );
  expect(
    ninePatchButtonLabelSpan(tester, 'Diplomatic protest').style?.color,
    isNot(EditorialMonoclePalette.accentBright),
  );
}

Future<void> expectNinePatchMutedDangerWins(WidgetTester tester) async {
  await pumpNinePatchButton(
    tester,
    onPressed: () {},
    dangerVariant: true,
    mutedVariant: true,
    child: const Text('Declare War'),
  );
  expectNinePatchBorderColor(tester, EditorialMonoclePalette.danger);
  expect(
    (ninePatchButtonSurfaceDecoration(tester).border! as Border).top.color,
    isNot(EditorialMonoclePalette.accentDim),
  );
  expectNinePatchLabelColor(
    tester,
    'Declare War',
    EditorialMonoclePalette.danger,
  );
}

Future<void> expectNinePatchDefaultRegression(WidgetTester tester) async {
  await pumpNinePatchButton(tester, onPressed: () {});
  expectNinePatchBorderColor(tester, EditorialMonoclePalette.border);
  expect(
    (ninePatchButtonSurfaceDecoration(tester).border! as Border).top.color,
    isNot(EditorialMonoclePalette.accentDim),
  );
  expectNinePatchLabelColor(
    tester,
    'Confirm',
    EditorialMonoclePalette.accent,
  );
  expect(
    ninePatchButtonLabelSpan(tester, 'Confirm').style?.color,
    isNot(EditorialMonoclePalette.muted),
  );
}

void expectMutedCornerAlphaScaleContract() {
  expect(CtNinePatchButton.mutedCornerAlphaScale, 0.5);
  expect(
    CtNinePatchButton.defaultCornerAlpha *
        CtNinePatchButton.mutedCornerAlphaScale,
    closeTo(0.375, 1e-9),
  );
  expect(
    CtNinePatchButton.hoverCornerAlpha *
        CtNinePatchButton.mutedCornerAlphaScale,
    closeTo(0.5, 1e-9),
  );
}
