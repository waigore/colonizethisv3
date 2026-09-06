// Pump/decoration helpers for CtTopBar widget tests (Refs #4734 Slice H).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const ValueKey<String> kCtTopBarTestIconKey =
    ValueKey<String>('ctTopBarTestIcon');
const ValueKey<String> kCtTopBarTestTrailingKey =
    ValueKey<String>('ctTopBarTestTrailing');

Future<void> pumpCtTopBar(WidgetTester tester, Widget child) async {
  await pumpAppShell(
    tester,
    child: Scaffold(
      body: Column(children: <Widget>[child]),
    ),
  );
}

DecoratedBox ctTopBarSurface(WidgetTester tester) {
  return tester.widget<DecoratedBox>(
    find.byKey(const ValueKey<String>('ctTopBarSurface')),
  );
}

const CtTopBar kCtTopBarProduction = CtTopBar(title: 'Production');

const CtTopBar kCtTopBarProductionWithMapLabel = CtTopBar(
  title: 'Production',
  backButtonLabel: 'Map',
);

void expectCtTopBarAccentDimBottomBorder(BoxDecoration deco) {
  final Border border = deco.border! as Border;
  expect(border.top, BorderSide.none);
  expect(border.left, BorderSide.none);
  expect(border.right, BorderSide.none);
  expect(border.bottom.color, EditorialMonoclePalette.accentDim);
  expect(border.bottom.width, CtTopBar.borderWidth);
  expect(CtTopBar.borderWidth, 1);
}
