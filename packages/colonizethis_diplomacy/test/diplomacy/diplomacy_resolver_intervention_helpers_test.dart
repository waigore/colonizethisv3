import 'package:colonizethis_combat/src/combat/conflict_detection.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show kTechIdPropaganda;
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('intervention helpers', () {
    test('needsInterventionChoice returns gp id with embassy for attacked minor', () {
      final game = diplomacyGame(
        id: 'g1',
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
      final game = diplomacyGame(
        id: 'g1',
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
      final game = diplomacyGame(
        id: 'g1',
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker', isHuman: false),
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
      final after = applyInterventionChoice(game, ctx, 'gp1', InterventionChoice.doNothing);
      expect(after.overtureStates, isEmpty);
      expect(
        after.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.interventionDoNothing),
        isNotEmpty,
      );
    });

    test('applyInterventionChoice protest reduces relation score with attacker', () {
      final game = diplomacyGame(
        id: 'g1',
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Attacker', isHuman: false),
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
      final after = applyInterventionChoice(game, ctx, 'gp1', InterventionChoice.protest);
      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.score, lessThan(60));
    });

    test(
      'applyInterventionChoice protest uses smaller penalty when attacker has Propaganda',
      () {
        final game = diplomacyGame(
          id: 'g1',
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
      final game = diplomacyGame(
        id: 'g1',
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
  });
}
