// GAME30002 Formal allies line and invasion Declare War shared body (Refs #4409).

import 'package:colonizethis_app/features/game/widgets/diplomacy/invade_province_declare_war_body.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_detail_screen_test_support.dart';
import 'widget_test_assets.dart';

const _franceId = 'gp3';

Game _spainWithFranceAlly({required bool franceAtWarWithHuman}) {
  return Game(
    id: 'formal-allies',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: const [
      Player(
        id: diplomacyDetailHumanId,
        displayName: 'Portugal',
        isHuman: true,
      ),
      Player(id: diplomacyDetailOtherId, displayName: 'Spain', isHuman: false),
      Player(id: _franceId, displayName: 'France', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: diplomacyDetailOtherId,
        factionId2: _franceId,
        formalAlliance: true,
      ),
      if (franceAtWarWithHuman)
        DiplomacyRelation(
          factionId1: diplomacyDetailHumanId,
          factionId2: _franceId,
          state: RelationState.atWar,
        ),
    ],
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(preloadNinePatchImage);

  testWidgets(
    'GAME30002 Formal allies names a persisted ally the confirm would omit',
    (tester) async {
      final game = _spainWithFranceAlly(franceAtWarWithHuman: true);
      await pumpDiplomacyDetailOtherGp(
        tester,
        game: game,
        relation: game.diplomacyRelations.first,
      );

      expect(find.text('Formal allies: France'), findsOneWidget);
    },
  );

  testWidgets(
    'GAME30002 omits Formal allies when the viewed GP has no other-GP treaty',
    (tester) async {
      final game = diplomacyDetailMinimalGame();
      await pumpDiplomacyDetailOtherGp(
        tester,
        game: game,
        relation: game.diplomacyRelations.first,
      );

      expect(find.textContaining('Formal allies:'), findsNothing);
    },
  );

  test('invasion declare-war body shares third-party Effect lines', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final game = _spainWithFranceAlly(franceAtWarWithHuman: false);
    final body = invadeProvinceDeclareWarBody(
      l10n: l10n,
      game: game,
      humanPlayerId: diplomacyDetailHumanId,
      targetFactionId: diplomacyDetailOtherId,
      ownerLabel: 'Spain',
    );
    expect(body, contains('Spain'));
    expect(
      body,
      contains(
        'France holds a formal alliance with Spain and may be called to defend',
      ),
    );
  });
}
