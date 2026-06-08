import 'package:colonizethis_combat/src/combat/conflict_detection.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdPropaganda;
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('intervention helpers', () {
    test('needsInterventionChoice returns gp id with embassy for attacked minor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
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
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );

      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, 'gp1');
    });

    test('needsInterventionChoice returns null when defender is not minor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'gp2',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp1', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      expect(needsInterventionChoice(game, ctx), isNull);
    });

    test('applyInterventionChoice doNothing clears overtures and logs event', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker', isHuman: false),
        ],
        diplomacyRelations: const [],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
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
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = applyInterventionChoice(game, ctx, 'gp1', InterventionChoice.doNothing);
      expect(after.overtureStates, isEmpty);
      expect(
        after.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.interventionDoNothing),
        isNotEmpty,
      );
    });

    test('applyInterventionChoice protest reduces relation score with attacker', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 60,
            level: RelationLevel.friendly,
          ),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = applyInterventionChoice(game, ctx, 'gp1', InterventionChoice.protest);
      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.score, lessThan(60));
    });

    test(
      'applyInterventionChoice protest uses smaller penalty when attacker has Propaganda',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            const Player(id: 'gp1', displayName: 'Human', isHuman: true),
            const Player(id: 'gp2', displayName: 'Attacker', isHuman: false)
                .copyWith(techUnlocked: const {kTechIdPropaganda: true}),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 60,
              level: RelationLevel.friendly,
            ),
          ],
        );
        final ctx = BattleContext(
          provinceId: 'P1',
          regionId: 'oldWorld',
          defenderFactionId: 'minor1',
          defenderUnitIds: const [],
          attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
          fortLevel: 0,
          terrain: 'plains',
        );
        final after =
            applyInterventionChoice(game, ctx, 'gp1', InterventionChoice.protest);
        final rel = getRelation(after, 'gp1', 'gp2');
        expect(rel!.score, 55);
      },
    );

    test('needsInterventionChoice returns null when no GP has embassy for minor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'minor1',
        defenderUnitIds: const [],
        attackers: const [AttackingSide(factionId: 'gp2', unitIds: [])],
        fortLevel: 0,
        terrain: 'plains',
      );
      final gpId = needsInterventionChoice(game, ctx);
      expect(gpId, isNull);
    });

    test(
        'declare war on minor with another GP invested: sets war state (scenario anchor)',
        () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 3,
          ),
          oldWorld: RegionData(
            provinces: const [
              Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: const {
            tileKey: 'gp1', // gp1 has purchased land in minor1 province
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor GP', isHuman: false),
        ],
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

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: ow, ownerId: 'minor1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: const {
            tileKey: 'gp1',
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
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

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(
            phase: TurnPhase.orders,
            turnNumber: 1,
          ),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: nw, ownerId: 'tribe1'),
            ],
            units: [],
          ),
          purchasedTilesByTileKey: const {
            tileKey: 'gp1',
          },
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human GP', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker GP', isHuman: false),
        ],
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
