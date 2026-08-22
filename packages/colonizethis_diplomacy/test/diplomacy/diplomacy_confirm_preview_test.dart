import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_confirm_preview_cases.dart';
import 'diplomacy_confirm_preview_label_orders.dart';

void main() {
  Game baseGame() => diplomacyGame(
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
    tribes: const [Tribe(id: previewTribeId, displayName: 'Aztec')],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: previewMinorId,
        ),
        Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          ownerId: previewTribeId,
        ),
      ],
    ),
  );

  for (final c in confirmPreviewCases()) {
    test(c.name, () {
      final lines = buildDiplomacyConfirmPreviewLines(
        order: c.order,
        game: baseGame(),
        humanPlayerId: previewHumanId,
        targetDisplayName: c.targetDisplayName,
      );
      c.assertLines(lines, lines.join('\n'));
    });
  }

  test('preview lines stay short structured labels without prose wall', () {
    for (final order in structuredLabelOrders()) {
      final lines = buildDiplomacyConfirmPreviewLines(
        order: order,
        game: baseGame(),
        humanPlayerId: previewHumanId,
        targetDisplayName: 'Spain',
      );
      expect(lines, isNotEmpty);
      expect(lines.length, lessThanOrEqualTo(5));
      for (final line in lines) {
        expect(
          line.startsWith('Cost:') ||
              line.startsWith('Effect:') ||
              line.startsWith('When:'),
          isTrue,
          reason: 'Unexpected line prefix in $order: $line',
        );
      }
    }
  });

  test('grant aid and subsidy preview lines', () {
    final grant = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.grantAid,
        targetFactionId: previewMinorId,
        amount: 2000,
      ),
      game: baseGame(),
      humanPlayerId: previewHumanId,
      targetDisplayName: 'Bavaria',
    );
    expect(grant.join('\n'), contains('£2000'));
    expect(grant.join('\n').toLowerCase(), contains('standing'));

    final subsidy = buildDiplomacyConfirmPreviewLines(
      order: const DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: previewMinorId,
        amount: 15,
      ),
      game: baseGame(),
      humanPlayerId: previewHumanId,
      targetDisplayName: 'Bavaria',
    );
    final subsidyBody = subsidy.join('\n');
    expect(subsidyBody, contains('No per-turn gold'));
    expect(
      subsidyBody,
      contains(
        subsidyFillPriceConsequence(targetDisplayName: 'Bavaria', percent: 15),
      ),
    );
    expect(
      subsidyBody.toLowerCase(),
      isNot(contains('market terms are affected')),
    );
    expect(subsidyBody, isNot(contains('+0.2')));
    expect(subsidyBody, isNot(contains('-50')));
    expect(subsidyBody, isNot(contains('-10')));
  });
}
