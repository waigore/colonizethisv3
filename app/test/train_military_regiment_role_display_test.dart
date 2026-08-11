import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/features/game/widgets/train/train_military_regiment_role_display.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  final l10n = lookupAppLocalizations(const Locale('en'));

  group('TrainMilitaryRegimentRoleDisplay', () {
    test('culverin shows heavy artillery and siege guns gist', () {
      final stats = regimentStatsById('culverin');
      expect(stats, isNotNull);
      expect(
        TrainMilitaryRegimentRoleDisplay.categoryLabel(l10n, stats!.category),
        l10n.trainMilitary_categoryHeavyArtillery,
      );
      expect(
        TrainMilitaryRegimentRoleDisplay.combatRoleGist(l10n, stats.category),
        l10n.trainMilitary_combatGistHeavyArtillery,
      );
      expect(
        TrainMilitaryRegimentRoleDisplay.categoryRoleLineForRegiment(
          l10n,
          'culverin',
        ),
        'Heavy artillery · Siege guns',
      );
    });

    test('pikemen and arquebusiers benefit lines differ by category', () {
      final pikemen = regimentStatsById('pikemen')!;
      final arquebusiers = regimentStatsById('arquebusiers')!;
      final pikemenLine = TrainMilitaryRegimentRoleDisplay.categoryRoleLine(
        l10n,
        pikemen.category,
      );
      final arquebusiersLine = TrainMilitaryRegimentRoleDisplay.categoryRoleLine(
        l10n,
        arquebusiers.category,
      );
      expect(pikemenLine, 'Regular infantry · Melee line');
      expect(arquebusiersLine, 'Heavy infantry · Ranged firepower');
      expect(pikemenLine, isNot(equals(arquebusiersLine)));
    });

    test('squires food upkeep matches catalog', () {
      expect(
        TrainMilitaryRegimentRoleDisplay.foodUpkeepForRegiment('squires'),
        RegimentEconomyCatalog.squires.foodUpkeep,
      );
      expect(
        TrainMilitaryRegimentRoleDisplay.foodUpkeepLine(
          l10n,
          RegimentEconomyCatalog.squires.foodUpkeep,
        ),
        '${RegimentEconomyCatalog.squires.foodUpkeep} food / turn',
      );
    });
  });
}
