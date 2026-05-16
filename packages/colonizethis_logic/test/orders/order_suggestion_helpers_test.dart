/// Regression tests for [filterArmyMoveOrdersByDiplomacy] / shared diplomacy
/// filtering used on AI army-move paths (Refs #2394).
library;

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const ow = 'oldWorld';
  const gpId = 'gp1';
  const minorId = 'minor_doc';

  Game gameWithMinorProvince({
    required List<DiplomacyRelation> diplomacyRelations,
  }) {
    return Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            const Province(
              id: '$ow|P_gp',
              regionId: ow,
              ownerId: gpId,
            ),
            const Province(
              id: '$ow|P_minor',
              regionId: ow,
              ownerId: minorId,
            ),
          ],
        ),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: gpId, displayName: 'GP1', isHuman: true),
      ],
      minorNations: const [
        MinorNation(id: minorId, displayName: 'Minor Doc'),
      ],
      diplomacyRelations: diplomacyRelations,
    );
  }

  group('filterArmyMoveOrdersByDiplomacy', () {
    test('drops move into minor-owned province when relation row is absent', () {
      final game = gameWithMinorProvince(diplomacyRelations: const []);
      const orders = [
        ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$ow|P_minor'),
      ];
      final out = filterArmyMoveOrdersByDiplomacy(game, gpId, orders);
      expect(out, isEmpty);
    });

    test('keeps move into minor province when at war (relation row present)', () {
      final game = gameWithMinorProvince(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: gpId,
            factionId2: minorId,
            state: RelationState.atWar,
          ),
        ],
      );
      const orders = [
        ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$ow|P_minor'),
      ];
      final out = filterArmyMoveOrdersByDiplomacy(game, gpId, orders);
      expect(out, orders);
    });

    test('drops move into minor province when explicitly at peace', () {
      final game = gameWithMinorProvince(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: gpId,
            factionId2: minorId,
            state: RelationState.atPeace,
          ),
        ],
      );
      const orders = [
        ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$ow|P_minor'),
      ];
      final out = filterArmyMoveOrdersByDiplomacy(game, gpId, orders);
      expect(out, isEmpty);
    });

    test('keeps reordering-only move within own provinces', () {
      final game = gameWithMinorProvince(diplomacyRelations: const []);
      const orders = [
        ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$ow|P_gp'),
      ];
      final out = filterArmyMoveOrdersByDiplomacy(game, gpId, orders);
      expect(out, orders);
    });

    test('keeps move into minor at peace when draft orders declare war', () {
      final game = gameWithMinorProvince(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: gpId,
            factionId2: minorId,
            state: RelationState.atPeace,
          ),
        ],
      );
      const armyOrders = [
        ArmyMoveOrder(armyId: 'a1', destinationProvinceId: '$ow|P_minor'),
      ];
      final draftOrders = Orders(
        diplomaticOrdersByPlayerId: {
          gpId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: minorId,
            ),
          ],
        },
      );
      final out = filterArmyMoveOrdersByDiplomacy(
        game,
        gpId,
        armyOrders,
        draftOrders: draftOrders,
      );
      expect(out, armyOrders);
    });
  });
}
