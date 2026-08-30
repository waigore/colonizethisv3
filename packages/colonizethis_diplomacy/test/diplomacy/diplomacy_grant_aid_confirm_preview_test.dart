import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_confirm_preview_cases.dart';

Game _grantPreviewGame({required num pairScore}) {
  return diplomacyGame(
    players: const [
      Player(
        id: previewHumanId,
        displayName: 'England',
        isHuman: true,
        treasury: 50_000,
      ),
      Player(id: previewTargetGp, displayName: 'Spain', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: previewMinorId, displayName: 'Bavaria'),
    ],
    diplomacyRelations: [
      peaceRelation(previewHumanId, previewMinorId, pairScore),
    ],
  );
}

List<String> _grantLines({required Game game, required int amount}) {
  return buildDiplomacyConfirmPreviewLines(
    order: DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: previewMinorId,
      amount: amount,
    ),
    game: game,
    humanPlayerId: previewHumanId,
    targetDisplayName: 'Bavaria',
  );
}

void main() {
  test(
    'grant aid Cost names amount and Effect says larger gift does not help',
    () {
      final lines = _grantLines(
        game: _grantPreviewGame(pairScore: 50),
        amount: 3000,
      );
      final body = lines.join('\n');
      expect(
        body,
        contains('Cost: £3000 from your treasury when the grant resolves.'),
      );
      expect(
        body,
        contains(
          'Effect: Standing with Bavaria improves when the grant resolves.',
        ),
      );
      expect(
        body,
        contains(
          'Effect: A larger gift this turn does not improve standing further.',
        ),
      );
    },
  );

  test('grant aid standing-word lines do not change with amount', () {
    final game = _grantPreviewGame(pairScore: 50);
    final at1000 = _grantLines(game: game, amount: 1000);
    final at3000 = _grantLines(game: game, amount: 3000);
    expect(at1000[0], contains('£1000'));
    expect(at3000[0], contains('£3000'));
    expect(at1000.skip(1).toList(), at3000.skip(1).toList());
  });

  test('grant aid standing word becomes Neutral from Wary at score 45', () {
    final body = _grantLines(
      game: _grantPreviewGame(pairScore: 45),
      amount: 1000,
    ).join('\n');
    expect(body, contains('Effect: Standing word becomes Neutral.'));
    expect(body, isNot(contains('becomes Wary')));
    expect(body, isNot(contains('stays Wary')));
  });

  test('grant aid standing word stays Wary when still in band', () {
    final body = _grantLines(
      game: _grantPreviewGame(pairScore: 40),
      amount: 1000,
    ).join('\n');
    expect(body, contains('Effect: Standing word stays Wary.'));
  });

  test('grant aid standing word stays Devoted at score 95', () {
    final body = _grantLines(
      game: _grantPreviewGame(pairScore: 95),
      amount: 1000,
    ).join('\n');
    expect(body, contains('Effect: Standing word stays Devoted.'));
  });

  test('grant aid Effect omits scores, +5, penalties, and order ids', () {
    final body = _grantLines(
      game: _grantPreviewGame(pairScore: 45),
      amount: 1000,
    ).join('\n');
    expect(body, isNot(contains('+5')));
    expect(body, isNot(contains('45')));
    expect(body, isNot(contains('50')));
    expect(body, isNot(contains('-50')));
    expect(body, isNot(contains('-10')));
    expect(body, isNot(contains('formalAlliance')));
    expect(body, isNot(contains('grantAid')));
  });

  test('subsidy preview omits grant standing-word copy', () {
    final body = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: previewMinorId,
        amount: 10,
      ),
      game: _grantPreviewGame(pairScore: 45),
      humanPlayerId: previewHumanId,
      targetDisplayName: 'Bavaria',
    ).join('\n');
    expect(body, contains('No per-turn gold'));
    expect(body, isNot(contains('Standing word')));
    expect(body, isNot(contains('larger gift')));
    expect(
      body,
      contains(
        subsidyFillPriceConsequence(targetDisplayName: 'Bavaria', percent: 10),
      ),
    );
  });
}
