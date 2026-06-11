import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('intervention in Diplomacy phase', () {
    test('human with embassy: resume with intervene declares war on aggressor', () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
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

      final pending = resolveDiplomacyPhase(game, orders);
      expect(pending.isPending, isTrue);
      expect(pending.pendingInterventions, isNotNull);
      final prompt = pending.pendingInterventions!.single;

      final resumed = resolveDiplomacyPhase(
        pending.game,
        orders,
        interventionDecisions: [
          InterventionDecision(
            aggressorGpId: prompt.aggressorGpId,
            defenderMinorOrTribeId: prompt.defenderMinorOrTribeId,
            interveningGpId: prompt.interveningGpId,
            choice: InterventionChoice.intervene,
          ),
        ],
      );
      expect(resumed.isPending, isFalse);
      final rel = getRelation(resumed.game, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.atWar, isTrue);
    });

    test('AI with embassy: 0% intervene probability clears overtures (do nothing)', () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(
            provinces: const [
              Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI friend', isHuman: false),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 20,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
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
      expect(result.isPending, isFalse);
      expect(getOverture(result.game, 'gp1', 'minor1'), isNull);
      expect(getRelation(result.game, 'gp1', 'gp2')?.atWar, isNot(isTrue));
    });

    test('Tribe defender with purchased land: pending intervention for human holder', () {
      const nw = 'newWorld';
      const tribeProvId = '$nw|T1';
      const tileKey = '$nw|T1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: tribeProvId, regionId: nw, ownerId: 'tribe1'),
            ],
            units: const [],
          ),
          purchasedTilesByTileKey: const {tileKey: 'gp1'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
        ],
        tribes: const [
          Tribe(id: 'tribe1', displayName: 'Tribe 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'tribe1',
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'tribe1',
            state: RelationState.atPeace,
          ),
        ],
      );

      final orders = Orders(
        diplomaticOrdersByPlayerId: const {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'tribe1',
            ),
          ],
        },
      );

      final result = resolveDiplomacyPhase(game, orders);
      expect(result.isPending, isTrue);
      expect(result.pendingInterventions!.single.defenderMinorOrTribeId, 'tribe1');
    });

    test('resolveTurnForGame returns TurnResolutionPendingIntervention', () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
            ],
            units: const [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'minor1',
            state: RelationState.atPeace,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
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

      final turnResult = resolveTurnForGame(
        game: game,
        topology: const MapTopology(),
        orders: orders,
      );
      expect(turnResult, isA<TurnResolutionPendingIntervention>());
      final pending = turnResult as TurnResolutionPendingIntervention;

      final complete = resumeTurnResolutionWithInterventionDecisions(
        game: pending.game,
        decisions: [
          InterventionDecision(
            aggressorGpId: 'gp2',
            defenderMinorOrTribeId: 'minor1',
            interveningGpId: 'gp1',
            choice: InterventionChoice.protest,
          ),
        ],
        config: TurnResolverConfig(
          topology: const MapTopology(),
          orders: orders,
        ),
      );
      expect(complete, isA<TurnResolutionComplete>());
      final rel = getRelation((complete as TurnResolutionComplete).game, 'gp1', 'gp2');
      expect(rel?.atPeace, isTrue);
      expect(rel!.score, lessThan(50));
    });
  });
}
