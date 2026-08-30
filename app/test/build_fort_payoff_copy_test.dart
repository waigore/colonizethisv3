import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('fortLevel 0 gist uses open field to wood siege copy', () {
    expect(
      buildFortPayoffGistLine(
        l10n: l10n,
        fromLabel: l10n.moveArmy_fortOpenField,
        toLabel: l10n.moveArmy_fortWoodSiege,
        turns: 1,
      ),
      'After this work: Open field → Wood fort siege · Takes 1 turn',
    );
  });

  test('fortLevel 1 gist uses wood to stone siege copy', () {
    expect(
      buildFortPayoffGistLine(
        l10n: l10n,
        fromLabel: l10n.moveArmy_fortWoodSiege,
        toLabel: l10n.moveArmy_fortStoneSiege,
        turns: 2,
      ),
      'After this work: Wood fort siege → Stone fort siege · Takes 2 turns',
    );
  });

  test('fortLevel 2 gist uses stone to modern siege copy', () {
    expect(
      buildFortPayoffGistLine(
        l10n: l10n,
        fromLabel: l10n.moveArmy_fortStoneSiege,
        toLabel: l10n.moveArmy_fortModernSiege,
        turns: 3,
      ),
      'After this work: Stone fort siege → Modern fort siege · Takes 3 turns',
    );
  });
}
