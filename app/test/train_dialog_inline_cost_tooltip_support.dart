// Pump helpers for train-dialog inline cost tooltip pins (Refs #3631, #4305).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget _localizedHost(Widget child) {
  return buildAppShell(
    child: Scaffold(body: Center(child: child)),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

String _humanPlayerId(Game game) =>
    game.players.firstWhere((p) => p.isHuman).id;

Future<void> _pumpDialog(WidgetTester tester, Widget dialog) async {
  await pumpAppShell(
    tester,
    viewport: const Size(420, 900),
    child: Scaffold(body: dialog),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    settle: true,
  );
}

/// Collects every mounted [Tooltip] message string.
List<String> _tooltipMessages(WidgetTester tester) {
  return tester
      .widgetList<Tooltip>(find.byType(Tooltip))
      .map((t) => t.message ?? '')
      .toList();
}
