// Case bodies for `greatPowerWarCountOnTarget` pin (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerExpandPhasePlannerGreatPowerWarCountCases() {
  group('greatPowerWarCountOnTarget', () {
    test('counts only Great Powers via diplomacy relations', () {
      final game = Game(
        id: 'g-gp-war-count-basic',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 12),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 10,
          ),
          DiplomacyRelation(
            factionId1: 'gp2',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 20,
          ),
          // Minor war against gp3 must NOT be counted.
          DiplomacyRelation(
            factionId1: 'minor1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 5,
          ),
          // Non-war relations against gp3 must NOT be counted.
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            score: 0,
          ),
        ],
      );
      expect(
        greatPowerWarCountOnTarget(game: game, targetGpId: 'gp3'),
        2,
        reason:
            'Only Great Power vs Great Power at-war relations against the '
            'target must contribute to the dogpile signal; minor wars and '
            'non-war states are ignored.',
      );
    });

    test('returns zero when no GP is at war with the target', () {
      final game = Game(
        id: 'g-gp-war-count-zero',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
        ],
      );
      expect(
        greatPowerWarCountOnTarget(game: game, targetGpId: 'gp3'),
        0,
        reason:
            'Targets without any active GP-vs-GP at-war relation must '
            'produce a zero count so the war-concentration gate does not '
            'suppress an otherwise valid declare-war candidate.',
      );
    });

    test('folds same-turn declare-war orders into the count', () {
      final game = Game(
        id: 'g-gp-war-count-same-turn',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
      );
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
          // Minor declarer must be ignored.
          'minor1': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
          // Non-declareWar order from a GP must be ignored.
          'gp1': [
            DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'gp3',
            ),
          ],
        },
      );
      expect(
        greatPowerWarCountOnTarget(
          game: game,
          targetGpId: 'gp3',
          sameTurnPriorDiplomaticOrders: priorOrders,
        ),
        1,
        reason:
            'Same-turn declarer set must include only Great Powers that '
            'committed a declareWar against the target; minor declarers '
            'and non-declareWar orders are filtered out.',
      );
    });

    test(
      'does not double-count a GP that both relates atWar and declares this turn',
      () {
        final game = Game(
          id: 'g-gp-war-count-dedupe',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'P1', isHuman: false),
            Player(id: 'gp2', displayName: 'P2', isHuman: false),
            Player(id: 'gp3', displayName: 'P3', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 10,
            ),
            DiplomacyRelation(
              factionId1: 'gp2',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 20,
            ),
          ],
        );
        const priorOrders = Orders(
          diplomaticOrdersByPlayerId: {
            // gp2 is already at war with gp3 AND declared this turn —
            // must be counted exactly once.
            'gp2': [
              DiplomaticOrder(
                type: DiplomaticOrderType.declareWar,
                targetFactionId: 'gp3',
              ),
            ],
          },
        );
        expect(
          greatPowerWarCountOnTarget(
            game: game,
            targetGpId: 'gp3',
            sameTurnPriorDiplomaticOrders: priorOrders,
          ),
          2,
          reason:
              'Resolved at-war partners and same-turn declarers must be '
              'merged into a single set so a GP appearing in both sources '
              'still contributes 1 to the dogpile count (not 2). Pins the '
              'set semantics required by the war-concentration suppression '
              'in diplomatic_candidate_scoring_declare_war.dart.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = Game(
        id: 'g-gp-war-count-determinism',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 25),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
          Player(id: 'gp3', displayName: 'P3', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      const priorOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
        },
      );
      final first = greatPowerWarCountOnTarget(
        game: game,
        targetGpId: 'gp3',
        sameTurnPriorDiplomaticOrders: priorOrders,
      );
      final second = greatPowerWarCountOnTarget(
        game: game,
        targetGpId: 'gp3',
        sameTurnPriorDiplomaticOrders: priorOrders,
      );
      final third = greatPowerWarCountOnTarget(
        game: game,
        targetGpId: 'gp3',
        sameTurnPriorDiplomaticOrders: priorOrders,
      );
      expect(
        first,
        second,
        reason:
            'Pure helper must return identical counts on repeated calls — '
            'required by issue #2509 Must-have #7 (phase planners are pure '
            'functions with deterministic inputs).',
      );
      expect(
        second,
        third,
        reason: 'Same as above across three consecutive calls.',
      );
    });
  });
}
