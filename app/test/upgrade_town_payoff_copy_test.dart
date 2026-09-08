import 'package:colonizethis_app/features/game/widgets/units/civilian/upgrade_town_payoff_copy.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('1→2 gist starts workshops and takes 1 turn (Refs #4747)', () {
    expect(
      upgradeTownPayoffGistLine(l10n: l10n, fromLevel: 1, turns: 1),
      'After this work: town workshops start · Takes 1 turn',
    );
  });

  test('2→3 gist warns pause until level 4 (Refs #4747)', () {
    expect(
      upgradeTownPayoffGistLine(
        l10n: l10n,
        fromLevel: 2,
        turns: 1,
        goodsClause: ' (+1 Lumber)',
      ),
      'After this work: town workshops pause until level 4 (+1 Lumber) · Takes 1 turn',
    );
  });

  test('3→4 gist resumes at double the level-2 rate (Refs #4747)', () {
    expect(
      upgradeTownPayoffGistLine(l10n: l10n, fromLevel: 3, turns: 1),
      'After this work: town workshops resume at double the level-2 rate · Takes 1 turn',
    );
  });

  test('goods clause names at most two display names', () {
    expect(
      upgradeTownPayoffGoodsClause(l10n, const {
        'lumber': 1,
        'fabric': 2,
        'castIron': 3,
      }),
      ' (+3 Cast iron, +2 Fabric)',
    );
  });

  test('empty bonus has no goods clause', () {
    expect(upgradeTownPayoffGoodsClause(l10n, const {}), '');
  });
}
