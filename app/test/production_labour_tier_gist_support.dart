// Labour Controls cost-gist read helpers (Refs #4734 Slice G).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show WorkerTier;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String productionLabourTierCostPlain(WidgetTester tester, WorkerTier tier) {
  final text = tester.widget<Text>(
    find.byKey(ValueKey<String>('production_labour_cost_${tier.id}')),
  );
  return text.textSpan!.toPlainText();
}

bool productionLabourTierCostHasDanger(
  WidgetTester tester,
  WorkerTier tier,
  String fragment,
) {
  final text = tester.widget<Text>(
    find.byKey(ValueKey<String>('production_labour_cost_${tier.id}')),
  );
  final span = text.textSpan! as TextSpan;
  var found = false;
  span.visitChildren((child) {
    if (child is! TextSpan) return true;
    if (child.text != fragment) return true;
    found = child.style?.color == EditorialMonoclePalette.danger;
    return false;
  });
  return found;
}
