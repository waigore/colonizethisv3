import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('survival offerPeace (Refs #2509)', () {
    test(
      'collapsed GP offerPeace ends GP war without reciprocal offer',
      () {
        final game = Game(
          id: 'g-collapsed-peace',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 3; i++)
                  Province(
                    id: 'oldWorld|gp2_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp2',
                  ),
                for (var i = 1; i <= 10; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp2', displayName: 'Collapsed', isHuman: false),
            Player(id: 'gp3', displayName: 'Strong', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
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
      },
    );

    test(
      'below-quota GP at eight OW provinces offerPeace ends war when enemy leads by one',
      () {
        final game = Game(
          id: 'g-below-quota-eight-lead-one',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 8; i++)
                  Province(
                    id: 'oldWorld|gp2_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp2',
                  ),
                for (var i = 1; i <= 9; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp2', displayName: 'Weak', isHuman: false),
            Player(id: 'gp3', displayName: 'Strong', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
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
      },
    );

    test(
      'below-quota GP at eight OW provinces offerPeace ends war when outmatched',
      () {
        final game = Game(
          id: 'g-below-quota-peace',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 70),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 8; i++)
                  Province(
                    id: 'oldWorld|gp2_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp2',
                  ),
                for (var i = 1; i <= 12; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp2', displayName: 'Weak', isHuman: false),
            Player(id: 'gp3', displayName: 'Strong', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
              score: 40,
              level: RelationLevel.neutral,
              state: RelationState.atWar,
            ),
          ],
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
        final game = Game(
          id: 'g-weak-six-peace',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 6; i++)
                  Province(
                    id: 'oldWorld|gp2_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp2',
                  ),
                for (var i = 1; i <= 10; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp2', displayName: 'Weak', isHuman: false),
            Player(id: 'gp3', displayName: 'Strong', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
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
      },
    );

    test(
      'GP at war with two GPs offerPeace ends one front without reciprocal offer',
      () {
        final game = Game(
          id: 'g-multi-front-peace',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 11; i++)
                  Province(
                    id: 'oldWorld|gp2_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp2',
                  ),
                for (var i = 1; i <= 12; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 1; i <= 10; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp2', displayName: 'Multi', isHuman: false),
            Player(id: 'gp3', displayName: 'FrontA', isHuman: false),
            Player(id: 'gp4', displayName: 'FrontB', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
              score: 40,
              level: RelationLevel.neutral,
              state: RelationState.atWar,
            ),
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
        final game = Game(
          id: 'g-sole-gp-peace',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 50),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 11; i++)
                  Province(
                    id: 'oldWorld|gp4_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp4',
                  ),
                for (var i = 1; i <= 12; i++)
                  Province(
                    id: 'oldWorld|gp3_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp3',
                  ),
                for (var i = 1; i <= 10; i++)
                  Province(
                    id: 'oldWorld|gp5_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp5',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp4', displayName: 'Sole', isHuman: false),
            Player(id: 'gp3', displayName: 'Blocker', isHuman: false),
            Player(id: 'gp5', displayName: 'Front', isHuman: false),
          ],
          diplomacyRelations: [
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
