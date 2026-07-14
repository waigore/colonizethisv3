// Shared 320 dp dialog pump harness for dialogs_320dp_min_viewport_part*_test.
// SPEC: SPEC/ui/mobile-adaptation.md § 7. Refs #4013 / #2870.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'min_viewport_harness.dart';

/// Minimum supported viewport dimensions for SPEC/ui/mobile-adaptation.md § 7.
const Size kDialogs320MinViewport = Size(kMinViewportWidth, 640);

/// Wide regression sentinel for the same overflow contract.
const Size kDialogs320WideRegressionViewport = Size(1024, 768);

/// Pumps [dialog] at [size] under the running editorial-monocle theme.
Future<void> pumpDialogs320At(
  WidgetTester tester,
  Widget dialog, {
  required Size size,
  bool settle = true,
}) async {
  await pumpAtMinViewport(
    tester,
    size: size,
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    child: Scaffold(body: Center(child: dialog)),
    settle: settle,
  );
}
