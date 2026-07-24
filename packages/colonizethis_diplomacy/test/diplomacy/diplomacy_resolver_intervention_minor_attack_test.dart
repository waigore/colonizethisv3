import 'package:colonizethis_combat/src/combat/conflict_detection.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('intervention minor/tribe attack detection', () {
    test(
        'declare war on minor with another GP invested: sets war state (scenario anchor)',
        () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';

      final game = diplomacyGame(
        id: 'g1',
        turnNumber: 3,
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor GP', isHuman: false),
        ],
        oldWorld: const RegionData(
          provinces: [
            Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
          ],
        ),
        purchasedTilesByTileKey: const {
          tileKey: 'gp1',
        },
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
        ],
      );

      final orders = Orders(
        diplomaticOrdersByPlayerId: const {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );

      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isTrue);
      expect(result.pendingInterventions, isNotNull);
      expect(result.pendingInterventions!.length, 1);
      expect(result.pendingInterventions!.first.interveningGpId, 'gp1');
      expect(result.pendingInterventions!.first.aggressorGpId, 'gp2');
      final after = result.game;
      final relGp2Minor = getRelation(after, 'gp2', 'minor1');
      expect(relGp2Minor, isNotNull);
      expect(relGp2Minor!.atWar, isTrue);
    });

    test(
        'needsInterventionChoice returns gp id when human GP has purchased land in attacked minor',
        () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = diplomacyGame(
        id: 'g1',
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        oldWorld: const RegionData(
          provinces: [
            Province(id: provinceId, regionId: ow, ownerId: 'minor1'),
          ],
        ),
        purchasedTilesByTileKey: const {
          tileKey: 'gp1',
        },
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: ow,
        defenderFactionId: 'minor1',
        defenderUnitIds: [],
        attackers: [
          AttackingSide(
            factionId: 'gp2',
            unitIds: [],
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, 'gp1');
    });

    test(
        'needsInterventionChoice returns gp id when human GP has purchased land in attacked tribe',
        () {
      const nw = 'newWorld';
      const provinceId = '$nw|T1';
      const tileKey = '$nw|T1|0|0';

      final game = diplomacyGame(
        id: 'g1',
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        newWorld: const RegionData(
          provinces: [
            Province(id: provinceId, regionId: nw, ownerId: 'tribe1'),
          ],
        ),
        purchasedTilesByTileKey: const {
          tileKey: 'gp1',
        },
        tribes: const [
          Tribe(id: 'tribe1', displayName: 'Tribe 1'),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: nw,
        defenderFactionId: 'tribe1',
        defenderUnitIds: [],
        attackers: [
          AttackingSide(
            factionId: 'gp2',
            unitIds: [],
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, 'gp1');
    });
  });
}
