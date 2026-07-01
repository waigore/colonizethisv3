import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_game_fixtures.dart';

const _gp2gp3AtWar = DiplomacyRelation(
  factionId1: 'gp2',
  factionId2: 'gp3',
  score: 40,
  level: RelationLevel.neutral,
  state: RelationState.atWar,
);

const _gp2gp3Players = [
  Player(id: 'gp2', displayName: 'Weak', isHuman: false),
  Player(id: 'gp3', displayName: 'Strong', isHuman: false),
];

void main() {
  group('survival offerPeace (Refs #2509)', () {
    test(
      'collapsed GP offerPeace ends GP war without reciprocal offer',
      () {
        final game = survivalPeaceProvinceGame(
          id: 'g-collapsed-peace',
          turnNumber: 10,
          provinceCountsByGpId: const {'gp2': 3, 'gp3': 10},
          players: const [
            Player(id: 'gp2', displayName: 'Collapsed', isHuman: false),
            Player(id: 'gp3', displayName: 'Strong', isHuman: false),
          ],
          diplomacyRelations: const [_gp2gp3AtWar],
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp2': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        final after = resolveDiplomacyPhase(game, orders).game;
        expect(getRelation(after, 'gp2', 'gp3')!.atPeace, isTrue);
      },
    );

    test(
      'below-quota GP at eight OW provinces offerPeace ends war when enemy leads by one',
      () {
        final game = survivalPeaceProvinceGame(
          id: 'g-below-quota-eight-lead-one',
          turnNumber: 8,
          provinceCountsByGpId: const {'gp2': 8, 'gp3': 9},
          players: _gp2gp3Players,
          diplomacyRelations: const [_gp2gp3AtWar],
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp2': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        final after = resolveDiplomacyPhase(game, orders).game;
        expect(getRelation(after, 'gp2', 'gp3')!.atPeace, isTrue);
      },
    );

    test(
      'below-quota GP at eight OW provinces offerPeace ends war when outmatched',
      () {
        final game = survivalPeaceProvinceGame(
          id: 'g-below-quota-peace',
          turnNumber: 70,
          provinceCountsByGpId: const {'gp2': 8, 'gp3': 12},
          players: _gp2gp3Players,
          diplomacyRelations: const [_gp2gp3AtWar],
        );
        expect(
          isBelowObserverConquestQuota(
            oldWorldProvinceCountOwnedBy(game, 'gp2'),
          ),
          isTrue,
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp2': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        final after = resolveDiplomacyPhase(game, orders).game;
        expect(getRelation(after, 'gp2', 'gp3')!.atPeace, isTrue);
      },
    );

    test(
      'weak GP at six OW provinces offerPeace ends GP war without reciprocal offer',
      () {
        final game = survivalPeaceProvinceGame(
          id: 'g-weak-six-peace',
          turnNumber: 10,
          provinceCountsByGpId: const {'gp2': 6, 'gp3': 10},
          players: _gp2gp3Players,
          diplomacyRelations: const [_gp2gp3AtWar],
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp2': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        final after = resolveDiplomacyPhase(game, orders).game;
        expect(getRelation(after, 'gp2', 'gp3')!.atPeace, isTrue);
      },
    );

    test(
      'GP at war with two GPs offerPeace ends one front without reciprocal offer',
      () {
        final game = survivalPeaceProvinceGame(
          id: 'g-multi-front-peace',
          turnNumber: 50,
          provinceCountsByGpId: const {'gp2': 11, 'gp3': 12, 'gp4': 10},
          players: const [
            Player(id: 'gp2', displayName: 'Multi', isHuman: false),
            Player(id: 'gp3', displayName: 'FrontA', isHuman: false),
            Player(id: 'gp4', displayName: 'FrontB', isHuman: false),
          ],
          diplomacyRelations: const [
            _gp2gp3AtWar,
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp4',
              score: 40,
              level: RelationLevel.neutral,
              state: RelationState.atWar,
            ),
          ],
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp2': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        final after = resolveDiplomacyPhase(game, orders).game;
        expect(getRelation(after, 'gp2', 'gp3')!.atPeace, isTrue);
        expect(getRelation(after, 'gp2', 'gp4')!.atWar, isTrue);
      },
    );

    test(
      'sole GP war offerPeace ends front without reciprocal offer',
      () {
        final game = survivalPeaceProvinceGame(
          id: 'g-sole-gp-peace',
          turnNumber: 50,
          provinceCountsByGpId: const {'gp4': 11, 'gp3': 12, 'gp5': 10},
          players: const [
            Player(id: 'gp4', displayName: 'Sole', isHuman: false),
            Player(id: 'gp3', displayName: 'Blocker', isHuman: false),
            Player(id: 'gp5', displayName: 'Front', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp4',
              factionId2: 'gp5',
              score: 40,
              level: RelationLevel.neutral,
              state: RelationState.atWar,
            ),
          ],
        );
        final orders = Orders(
          diplomaticOrdersByPlayerId: {
            'gp4': const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp5',
              ),
            ],
          },
        );
        final after = resolveDiplomacyPhase(game, orders).game;
        expect(getRelation(after, 'gp4', 'gp5')!.atPeace, isTrue);
      },
    );
  });
}
