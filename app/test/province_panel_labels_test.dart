import 'package:colonizethis_app/features/game/widgets/province_panel_labels.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;
import 'package:colonizethis_models/colonizethis_models.dart' show UnitStatus;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('regimentTypeDisplayLabel uses l10n for catalog id', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(regimentTypeDisplayLabel(l10n, 'peasant_levies'), 'Peasant levies');
    expect(regimentTypeDisplayLabel(l10n, 'unknown_regiment_x'), 'unknown_regiment_x');
  });

  test('shipTypeDisplayLabel uses l10n for catalog id', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(shipTypeDisplayLabel(l10n, 'carrack'), 'Carrack');
    expect(shipTypeDisplayLabel(l10n, 'future_hull'), 'future_hull');
  });

  test('workOrderTargetDisplayLabel maps build_improvement', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      workOrderTargetDisplayLabel(l10n, kWorkTargetBuildImprovement),
      'build improvement',
    );
  });

  test('unitStatusDisplayLabel maps idle', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(unitStatusDisplayLabel(l10n, UnitStatus.idle), 'idle');
  });
}
