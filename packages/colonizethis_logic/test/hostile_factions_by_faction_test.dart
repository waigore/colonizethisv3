import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  Game minimalGame(List<DiplomacyRelation> relations) => Game(
    id: 'g',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: const [
      Player(id: 'a', displayName: 'A', isHuman: true),
      Player(id: 'b', displayName: 'B', isHuman: false),
      Player(id: 'c', displayName: 'C', isHuman: false),
    ],
    diplomacyRelations: relations,
  );

  test(
    'Given no diplomacy rows When hostileFactionsByFaction Then empty map',
    () {
      final g = minimalGame(const []);
      expect(hostileFactionsByFaction(g), isEmpty);
      expect(enemiesOf(g, 'a'), isEmpty);
    },
  );

  test(
    'Given at-war pair When hostileFactionsByFaction Then symmetric edges',
    () {
      final g = minimalGame(const [
        DiplomacyRelation(
          factionId1: 'a',
          factionId2: 'b',
          state: RelationState.atWar,
        ),
      ]);
      final m = hostileFactionsByFaction(g);
      expect(m['a'], {'b'});
      expect(m['b'], {'a'});
      expect(factionsAtWar(g, 'a', 'b'), isTrue);
      expect(enemiesOf(g, 'a'), {'b'});
      expect(enemiesOf(g, 'b'), {'a'});
    },
  );

  test('Given three-party war star When graph Then hub sees both leaves', () {
    final g = minimalGame(const [
      DiplomacyRelation(
        factionId1: 'a',
        factionId2: 'b',
        state: RelationState.atWar,
      ),
      DiplomacyRelation(
        factionId1: 'a',
        factionId2: 'c',
        state: RelationState.atWar,
      ),
    ]);
    final m = hostileFactionsByFaction(g);
    expect(m['a'], {'b', 'c'});
    expect(m['b'], {'a'});
    expect(m['c'], {'a'});
    expect(enemiesOf(g, 'a'), {'b', 'c'});
  });

  test('Given atPeace only When hostileFactionsByFaction Then no edges', () {
    final g = minimalGame(const [
      DiplomacyRelation(
        factionId1: 'a',
        factionId2: 'b',
        state: RelationState.atPeace,
      ),
    ]);
    expect(hostileFactionsByFaction(g), isEmpty);
    expect(factionsAtWar(g, 'a', 'b'), isFalse);
  });
}
