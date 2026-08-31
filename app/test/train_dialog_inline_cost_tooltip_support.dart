// Pump/assert helpers for train_dialog_inline_cost_tooltip_test.dart (Refs #4680).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_dialog_chrome.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'app_shell_harness.dart';

Widget trainDialogInlineCostLocalizedHost(Widget child) {
  return buildAppShell(
    child: Scaffold(body: Center(child: child)),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

String trainDialogInlineCostHumanPlayerId(Game game) =>
    game.players.firstWhere((p) => p.isHuman).id;

Future<void> pumpTrainDialogInlineCostDialog(
  WidgetTester tester,
  Widget dialog,
) async {
  await pumpAppShell(
    tester,
    viewport: const Size(420, 900),
    child: Scaffold(body: dialog),
    localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    settle: true,
  );
}

List<String> trainDialogInlineCostTooltipMessages(WidgetTester tester) {
  return tester
      .widgetList<Tooltip>(find.byType(Tooltip))
      .map((t) => t.message ?? '')
      .toList();
}

Future<void> expectTrainDialogEnlargedCostIcons(WidgetTester tester) async {
  final Finder treasuryIcon = find.descendant(
    of: find.byType(TrainDialogInlineCost),
    matching: find.byIcon(Icons.payments_outlined),
  );
  expect(treasuryIcon, findsWidgets);
  for (final Icon icon in tester.widgetList<Icon>(treasuryIcon)) {
    expect(icon.size, kTrainDialogCostIconSize);
  }

  final Finder peasantIcon = find.descendant(
    of: find.byType(TrainDialogInlineCost),
    matching: find.byType(WorkerIcon),
  );
  expect(peasantIcon, findsWidgets);
  for (final WorkerIcon icon in tester.widgetList<WorkerIcon>(peasantIcon)) {
    expect(icon.size, kTrainDialogCostIconSize);
  }

  final Finder commodityIcon = find.descendant(
    of: find.byType(TrainDialogInlineCost),
    matching: find.byType(ResourceIcon),
  );
  expect(commodityIcon, findsWidgets);
  for (final ResourceIcon icon in tester.widgetList<ResourceIcon>(
    commodityIcon,
  )) {
    expect(icon.size, kTrainDialogCostIconSize);
  }

  final int segments = find.byType(TrainDialogInlineCost).evaluate().length;
  for (int i = 0; i < segments; i++) {
    final Size size = tester.getSize(
      find.byType(TrainDialogInlineCost).at(i),
    );
    expect(size.height, greaterThanOrEqualTo(kMinTouchTargetSize));
    expect(size.width, greaterThanOrEqualTo(kMinTouchTargetSize));
  }
}
