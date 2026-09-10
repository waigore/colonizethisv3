// Pins moveArmyFortSiegeGistForLevel copy (Refs #4764).
// SPEC/ui/move-army-dialog.md § Invasion intel.

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_invasion_intel.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_invasion_intel_labels.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('wood siege gist uses light walls and 1 extra gun', () {
    expect(
      moveArmyFortSiegeGistForLevel(l10n, 1),
      'Light walls soak some of the attack; the defender has 1 extra gun.',
    );
  });

  test('stone siege gist uses medium walls and 2 extra guns', () {
    expect(
      moveArmyFortSiegeGistForLevel(l10n, 2),
      'Medium walls soak more of the attack; the defender has 2 extra guns.',
    );
  });

  test('modern siege gist uses heavy walls and 3 extra guns', () {
    expect(
      moveArmyFortSiegeGistForLevel(l10n, 3),
      'Heavy walls soak much of the attack; the defender has 3 extra guns.',
    );
  });

  test('defender-role gist uses your fort wording', () {
    expect(
      moveArmyFortSiegeGistForLevel(l10n, 1, defenderRole: true),
      'Light walls soak some of the attack; your fort has 1 extra gun.',
    );
    expect(
      moveArmyFortSiegeGistForLevel(l10n, 2, defenderRole: true),
      'Medium walls soak more of the attack; your fort has 2 extra guns.',
    );
    expect(
      moveArmyFortSiegeGistForLevel(l10n, 3, defenderRole: true),
      'Heavy walls soak much of the attack; your fort has 3 extra guns.',
    );
  });

  test('open field, missing intel, and null fortLevel omit the gist', () {
    expect(moveArmyFortSiegeGistForLevel(l10n, 0), isNull);
    expect(moveArmyFortSiegeGistForLevel(l10n, null), isNull);
    expect(moveArmyFortSiegeGistForLevel(l10n, -1), isNull);
  });

  test('gists omit soak HP and damage-reduction percents', () {
    for (final level in [1, 2, 3]) {
      final attacker = moveArmyFortSiegeGistForLevel(l10n, level)!;
      final defender = moveArmyFortSiegeGistForLevel(
        l10n,
        level,
        defenderRole: true,
      )!;
      for (final gist in [attacker, defender]) {
        expect(gist, isNot(contains('10')));
        expect(gist, isNot(contains('20')));
        expect(gist, isNot(contains('30')));
        expect(gist, isNot(contains('%')));
        expect(gist, isNot(contains('HP')));
      }
    }
  });

  test('shared invasion summary lines omit the siege gist', () {
    final lines = moveArmyInvasionIntelSummaryLines(
      l10n,
      const MoveArmyInvasionIntelSummary(
        intelLevel: MoveArmyInvasionIntelLevel.full,
        defenderCombatCapableCount: 2,
        fortLevel: 1,
      ),
    );
    expect(lines, [
      l10n.moveArmy_defendersRegiments(2),
      l10n.moveArmy_fortWoodSiege,
    ]);
    expect(lines, isNot(contains(moveArmyFortSiegeGistForLevel(l10n, 1))));
  });
}
