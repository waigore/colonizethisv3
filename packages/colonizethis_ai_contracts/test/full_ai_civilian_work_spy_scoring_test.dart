import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Spy civilian-work scoring (Refs #3794 § Spy, AC23..AC31).
///
/// Verifies the unified, phase-dependent Spy scored pool (`steal_tech` /
/// `counter_spy`) replaces the lexicographic fallback (which always picked
/// `counter_spy` first alphabetically): the phase flag decides cross-type
/// preference, contextual bonuses differentiate same-target candidates, ties
/// break by province id, and an idle Spy with no candidates is reported.
void main() {
  const playerId = 'gp1';

  Game gameWith({
    List<Player> rivals = const [],
    List<DiplomacyRelation> diplomacyRelations = const [],
    List<Unit> oldWorldUnits = const [],
    Map<String, bool>? ownTechUnlocked,
    String? capitalProvinceId,
  }) => Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(units: oldWorldUnits),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: playerId,
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: capitalProvinceId,
        techUnlocked: ownTechUnlocked,
      ),
      ...rivals,
    ],
    diplomacyRelations: diplomacyRelations,
  );

  Player rival(
    String id, {
    required String capitalProvinceId,
    Map<String, bool>? techUnlocked,
  }) => Player(
    id: id,
    displayName: id,
    isHuman: false,
    capitalProvinceId: capitalProvinceId,
    techUnlocked: techUnlocked,
  );

  PlayerView spyViewFor(
    Game game, {
    String locationProvinceId = 'oldWorld|p1',
  }) => PlayerView(
    playerId: playerId,
    player: game.players.first,
    ownUnitsById: {
      's1': Unit(
        id: 's1',
        type: kUnitTypeSpy,
        ownerId: playerId,
        locationProvinceId: locationProvinceId,
      ),
    },
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );

  WorkOrder spy(String target, String tileKey) =>
      WorkOrder(unitId: 's1', target: target, targetTileKey: tileKey);

  group('Spy phase-dependent cross-type selection', () {
    test('AC23: non-DEVELOP prefers steal_tech over counter_spy', () {
      const stealTile = 'oldWorld|r1cap|0|0';
      const counterTile = 'oldWorld|p1|0|0';
      final game = gameWith(
        rivals: [rival('gp2', capitalProvinceId: 'oldWorld|r1cap')],
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetCounterSpy, counterTile),
          spy(kWorkTargetStealTech, stealTile),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: false,
      );
      expect(r.workOrders, hasLength(1));
      expect(r.workOrders.single.target, kWorkTargetStealTech);
      expect(r.workOrders.single.targetTileKey, stealTile);
      expect(r.idleEvents, isEmpty);
    });

    test('AC24: DEVELOP prefers counter_spy over alphabetically-later '
        'steal_tech', () {
      const stealTile = 'oldWorld|r1cap|0|0';
      const counterTile = 'oldWorld|p1|0|0';
      final game = gameWith(
        rivals: [rival('gp2', capitalProvinceId: 'oldWorld|r1cap')],
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetCounterSpy, counterTile),
          spy(kWorkTargetStealTech, stealTile),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      expect(r.workOrders.single.target, kWorkTargetCounterSpy);
      expect(r.workOrders.single.targetTileKey, counterTile);
    });
  });

  group('Spy steal_tech context scoring', () {
    test('AC25: higher tech deficit rival is preferred', () {
      const richTile = 'oldWorld|rich|0|0';
      const poorTile = 'oldWorld|poor|0|0';
      final game = gameWith(
        rivals: [
          rival(
            'gpRich',
            capitalProvinceId: 'oldWorld|rich',
            techUnlocked: const {'t1': true, 't2': true, 't3': true},
          ),
          rival(
            'gpPoor',
            capitalProvinceId: 'oldWorld|poor',
            techUnlocked: const {'t1': true},
          ),
        ],
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetStealTech, poorTile),
          spy(kWorkTargetStealTech, richTile),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: false,
      );
      expect(r.workOrders.single.targetTileKey, richTile);
    });

    test('AC26: at-war rival is preferred over at-peace rival', () {
      const warTile = 'oldWorld|warcap|0|0';
      const peaceTile = 'oldWorld|peacecap|0|0';
      final game = gameWith(
        rivals: [
          rival('gpWar', capitalProvinceId: 'oldWorld|warcap'),
          rival('gpPeace', capitalProvinceId: 'oldWorld|peacecap'),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: playerId,
            factionId2: 'gpWar',
            state: RelationState.atWar,
            score: 5,
          ),
        ],
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetStealTech, peaceTile),
          spy(kWorkTargetStealTech, warTile),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: false,
      );
      expect(r.workOrders.single.targetTileKey, warTile);
    });
  });

  group('Spy counter_spy context scoring', () {
    test('AC27: province with a foreign-owned Spy is preferred', () {
      const infestedTile = 'oldWorld|infested|0|0';
      const cleanTile = 'oldWorld|clean|0|0';
      final game = gameWith(
        rivals: [rival('gp2', capitalProvinceId: 'oldWorld|r1cap')],
        oldWorldUnits: [
          Unit(
            id: 'enemySpy',
            type: kUnitTypeSpy,
            ownerId: 'gp2',
            locationProvinceId: 'oldWorld|infested',
          ),
        ],
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetCounterSpy, cleanTile),
          spy(kWorkTargetCounterSpy, infestedTile),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      expect(r.workOrders.single.targetTileKey, infestedTile);
    });
  });

  group('Spy baseline / idle / determinism', () {
    test('AC28: single plain counter_spy candidate is selected', () {
      const tile = 'oldWorld|p1|0|0';
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [spy(kWorkTargetCounterSpy, tile)],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      expect(r.workOrders.single.target, kWorkTargetCounterSpy);
      expect(r.workOrders.single.targetTileKey, tile);
      expect(r.idleEvents, isEmpty);
    });

    test('AC29: idle Spy with no candidates logs no_suggestions', () {
      final game = gameWith();
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: const [],
        view: spyViewFor(game),
        game: game,
      );
      expect(r.workOrders, isEmpty);
      expect(r.idleEvents, hasLength(1));
      expect(r.idleEvents.single.unitId, 's1');
      expect(r.idleEvents.single.reason, 'no_suggestions');
    });

    test('AC30: equal scores break by province id (p1 before p2)', () {
      const tileP2 = 'oldWorld|p2|0|0';
      const tileP1 = 'oldWorld|p1|0|0';
      final game = gameWith();
      final first = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetCounterSpy, tileP2),
          spy(kWorkTargetCounterSpy, tileP1),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      final second = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetCounterSpy, tileP1),
          spy(kWorkTargetCounterSpy, tileP2),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      expect(first.workOrders.single.targetTileKey, tileP1);
      expect(second.workOrders.single.targetTileKey, tileP1);
    });
  });

  group('Spy GA tunability (AC31)', () {
    test('all spy scoring constants are registered in the registry', () {
      for (final name in const [
        'kSpyStealTechBaseWorkScore',
        'kSpyStealTechTechDeficitWeight',
        'kSpyStealTechHostileRelationsBonus',
        'kSpyStealTechProximityBonus',
        'kSpyCounterSpyBaseWorkScore',
        'kSpyCounterSpyEnemySpyPresenceBonus',
        'kSpyCounterSpyCapitalBonus',
        'kSpyCounterSpyBorderBonus',
        'kSpyPhaseStealTechBonus',
        'kSpyPhaseCounterSpyBonus',
      ]) {
        final p = AiParameterRegistry.byName(name);
        expect(p, isNotNull, reason: name);
        expect(p!.category, AiParameterCategory.victoryConfig, reason: name);
      }
    });
  });
}
